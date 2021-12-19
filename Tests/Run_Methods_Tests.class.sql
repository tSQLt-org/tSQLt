EXEC tSQLt.NewTestClass 'Run_Methods_Tests';
GO
CREATE PROC Run_Methods_Tests.[test all tSQLt.Run methods call the run method handler]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunMethodHandler';

  SELECT P.object_id,P.name
    INTO #Expected
    FROM sys.procedures AS P
   WHERE P.schema_id = SCHEMA_ID('tSQLt')
     AND P.name LIKE 'Run%'
     AND P.name NOT IN('RunTest');

  SELECT TOP(0) E.* INTO #Actual FROM #Expected E RIGHT JOIN #Expected X ON 1=0;
  
  DECLARE @cmd NVARCHAR(MAX) = 
  (
    SELECT 'EXEC tSQLt.'+QUOTENAME(P.name) + PP.ParameterList + ';INSERT INTO #Actual SELECT '+CAST(P.object_id AS NVARCHAR(MAX))+','''+P.name+''' FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog; TRUNCATE TABLE tSQLt.Private_RunMethodHandler_SpyProcedureLog;'
      FROM #Expected AS P
     OUTER APPLY
     (
       SELECT
           ISNULL(
             STUFF(
               (
                 SELECT ','+PP.name+'=NULL' FROM sys.parameters AS PP
                  WHERE P.object_id = PP.object_id
                  ORDER BY PP.parameter_id
                    FOR XML PATH(''),TYPE
               ).value('.','NVARCHAR(MAX)'),
               1,1,' '
             ),
             ''
           )
     )PP(ParameterList)
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC Run_Methods_Tests.[test Run truncates TestResult table]
AS
BEGIN

    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC ('CREATE PROC TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.Run TestCaseA;

    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunTestClass truncates TestResult table]
AS
BEGIN

    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.RunTestClass MyTestClass;
   
    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC Run_Methods_Tests.test_Run_handles_test_names_with_spaces
AS
BEGIN
  DECLARE @ProductMajorVersion INT;
  EXEC @ProductMajorVersion = tSQLt.Private_GetSQLProductMajorVersion;

  EXEC('CREATE SCHEMA MyTestClass;');
  EXEC('CREATE PROC MyTestClass.[Test Case A] AS RAISERROR(''<><><> GotHere <><><>'',16,10);');
    
  BEGIN TRY
      EXEC tSQLt.Run 'MyTestClass.Test Case A';
  END TRY
  BEGIN CATCH
    --This space left intentionally blank
  END CATCH
  SELECT Class, TestCase, Msg 
    INTO #Actual
    FROM tSQLt.TestResult;

  SELECT TOP(0) A.Class,A.TestCase,A.Msg AS [%Msg] INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase, '%<><><> GotHere <><><>%' Msg

  SELECT * INTO #Compare
    FROM(
      SELECT '>' _R_,* FROM #Actual AS A WHERE NOT EXISTS(SELECT 1 FROM #Expected E WHERE A.Class = E.Class AND A.TestCase = E.TestCase AND A.Msg LIKE E.[%Msg])
       UNION ALL
      SELECT '<' _R_,* FROM #Expected AS E WHERE NOT EXISTS(SELECT 1 FROM #Actual A WHERE A.Class = E.Class AND A.TestCase = E.TestCase AND A.Msg LIKE E.[%Msg])
    )X
    
    EXEC tSQLt.AssertEmptyTable '#Compare';
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run executes all tests in test class when called with class name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    EXEC tSQLt.Run 'innertest';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run executes single test when called with test case name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    EXEC tSQLt.Run 'innertest.testMe';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run re-executes single test when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest.testMe';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run re-executes testClass when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run deletes all entries from tSQLt.Run_LastExecution with same SPID]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt', 'Run_LastExecution';
    
    EXEC('EXEC tSQLt.DropClass New;');
    EXEC('CREATE SCHEMA New;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    INSERT tSQLt.Run_LastExecution(SessionId, LoginTime, TestName)
    SELECT @@SPID, '2009-09-09', '[Old1]' UNION ALL
    SELECT @@SPID, '2010-10-10', '[Old2]' UNION ALL
    SELECT @@SPID+10, '2011-11-11', '[Other]';   

    EXEC tSQLt.Run '[New]';
    
    SELECT TestName 
      INTO #Expected
      FROM tSQLt.Run_LastExecution
     WHERE 1=0;
     
    INSERT INTO #Expected(TestName)
    SELECT '[Other]' UNION ALL
    SELECT '[New]';

    SELECT TestName
      INTO #Actual
      FROM tSQLt.Run_LastExecution;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.test_RunTestClass_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RETURN 0;');

    EXEC tSQLt.RunTestClass MyTestClass;
    
    SELECT Class, TestCase 
      INTO #Actual
      FROM tSQLt.TestResult;
      
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase
      INTO #Expected;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test tSQLt.Run executes a test class even if there is a dbo owned object of the same name]
AS
BEGIN
  -- Assemble
  EXEC tSQLt.NewTestClass 'innertest';
  EXEC('CREATE PROC innertest.testMe as RETURN 0;');

  CREATE TABLE dbo.innertest(i INT);

  --Act
  EXEC tSQLt.Run 'innertest';

  --Assert
  SELECT Class, TestCase 
    INTO #Expected
    FROM tSQLt.TestResult
   WHERE 1=0;
   
  INSERT INTO #Expected(Class, TestCase)
  SELECT Class = 'innertest', TestCase = 'testMe';

  SELECT Class, TestCase
    INTO #Actual
    FROM tSQLt.TestResult;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_Run calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  
  EXEC tSQLt.Private_Run  @TestName = 'NoTestSchema.NoTest', @TestResultFormatter = 'SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_OutputTestResults uses the TestResultFormatter parameter]
AS
BEGIN
  EXEC('CREATE PROC Run_Methods_Tests.TemporaryTestResultFormatter AS RAISERROR(''GotHere'',16,10);');
  
  BEGIN TRY
    EXEC tSQLt.Private_OutputTestResults 'Run_Methods_Tests.TemporaryTestResultFormatter';
  END TRY
  BEGIN CATCH
    IF(ERROR_MESSAGE() LIKE '%GotHere%') RETURN 0;
  END CATCH
  EXEC tSQLt.Fail 'Run_Methods_Tests.TemporaryTestResultFormatter did not get called correctly';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunAll calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunTestClass';
  
  EXEC tSQLt.Private_RunAll 'SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithXmlResults calls Run with XmlResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithXmlResults @TestName = 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.XmlResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithXmlResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithXmlResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test NullTestResultFormatter prints no results from the tests]
AS
BEGIN
  EXEC tSQLt.FakeTable 'tSQLt.TestResult';
  
  INSERT INTO tSQLt.TestResult (TestCase) VALUES ('MyTest');
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.NullTestResultFormatter';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test procedure can be injected to display test results]
AS
BEGIN
    EXEC ('CREATE SCHEMA MyFormatterSchema;');
    EXEC ('CREATE TABLE MyFormatterSchema.Log (i INT DEFAULT(1));');
    EXEC ('CREATE PROC MyFormatterSchema.MyFormatter AS INSERT INTO MyFormatterSchema.Log DEFAULT VALUES;');
    EXEC tSQLt.SetTestResultFormatter 'MyFormatterSchema.MyFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.testA AS RETURN 0;');
    
    EXEC tSQLt.Run 'MyTestClass';
    
    CREATE TABLE #Expected (i int DEFAULT(1));
    INSERT INTO #Expected DEFAULT VALUES;
    
    EXEC tSQLt.AssertEqualsTable 'MyFormatterSchema.Log', '#Expected';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates <testsuites/> when no test cases in test suite]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.XmlResultFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    EXEC tSQLt.RunAll;
    
    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = CAST(Message AS NVARCHAR(MAX)) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    EXEC tSQLt.AssertEqualsString '<testsuites/>', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with test element when there is a passing test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  'testA', @Actual;
END;
GO   

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter handles even this:   ,/?'';:[o]]}\|{)(*&^%$#@""]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', ',/?'';:[o]}\|{)(*&^%$#@""', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  ',/?'';:[o]}\|{)(*&^%$#@""', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with test element and failure element when there is a failing test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'This test intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/failure/@message)[1]', 'NVARCHAR(MAX)');
    
    EXEC tSQLt.AssertEqualsString 'This test intentionally fails', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with multiple test elements some with failures]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Success', NULL);
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT TestCase.value('@name','NVARCHAR(MAX)') AS TestCase, TestCase.value('failure[1]/@message','NVARCHAR(MAX)') AS Msg
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TestCase,Msg
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with multiple test elements some with failures or errors]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT N'MyTestClass' AS Class, 4 tests, 2 failures, 1 errors
    INTO #expected
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter sets correct counts in testsuite attributes]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testE', 'XYZ', 'Failure', 'testE intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT *
    INTO #expected
    FROM (
      SELECT N'MyTestClass1' AS Class, 2 tests, 1 failures, 0 errors
      UNION ALL
      SELECT N'MyTestClass2' AS Class, 3 tests, 2 failures, 1 errors
    ) AS x;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter arranges multiple test cases into testsuites]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT Class,TestCase
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes duration for each test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:01.000', '2015-07-24T00:00:02.633');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-08-17T20:31:24.758');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:01.664', '2015-07-24T00:00:01.667');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase,
      TestCase.value('@time','NVARCHAR(MAX)') AS Time
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('MyTestClass1', 'testA', '0.138');
    INSERT INTO #Expected
    VALUES('MyTestClass1', 'testB', '1.633');
    INSERT INTO #Expected
    VALUES('MyTestClass2', 'testC', '2147483.647');
    INSERT INTO #Expected
    VALUES('MyTestClass2', 'testD', '0.003');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes start time and total duration per class]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:02.000', '2015-07-24T00:00:02.633');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-07-24T20:31:24.758');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:00.667', '2015-07-24T00:00:01.055');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
   
    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase,
      TestCase.value('@timestamp','NVARCHAR(MAX)') AS Timestamp,
      TestCase.value('@time','NVARCHAR(MAX)') AS Time
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('MyTestClass1', '2015-07-24T00:00:01', '1.633');
    INSERT INTO #Expected
    VALUES('MyTestClass2', '2015-07-24T00:00:00', '73884.091');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes other required fields]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (1,'MyTestClass1', 'testA', 'Failure');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (2,'MyTestClass1', 'testB', 'Success');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (3,'MyTestClass2', 'testC', 'Failure');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (4,'MyTestClass2', 'testD', 'Error');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@hostname','NVARCHAR(MAX)') AS Hostname,
      TestCase.value('../@id','NVARCHAR(MAX)') AS id,
      TestCase.value('../@package','NVARCHAR(MAX)') AS package,
      TestCase.value('@name','NVARCHAR(MAX)') AS Testname,
      TestCase.value('failure[1]/@type','NVARCHAR(MAX)') AS FailureType,
      TestCase.value('error[1]/@type','NVARCHAR(MAX)') AS ErrorType
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    DECLARE @ServerName NVARCHAR(MAX); SET @ServerName = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(MAX));
    INSERT INTO #Expected
    VALUES(@ServerName,1,'tSQLt','testA','tSQLt.Fail',NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,1,'tSQLt','testB',NULL,NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,2,'tSQLt','testC','tSQLt.Fail',NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,2,'tSQLt','testD',NULL,'SQL Error');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE Run_Methods_Tests.[test RunWithNullResults calls Run with NullTestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithNullResults 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.NullTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithNullResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithNullResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll executes the SetUp for each test case]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.SetUp AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SetUp AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    EXEC ('CREATE PROC B.testB2 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using RunAll]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using Run with single test]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run 'A.testA';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;

    EXEC tSQLt.Run 'B.testB';

    INSERT INTO #Actual
    SELECT Class, TestCase, Result
      FROM tSQLt.TestResult;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using Run with TestClass]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run 'A';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;

    EXEC tSQLt.Run 'B';

    INSERT INTO #Actual
    SELECT Class, TestCase, Result
      FROM tSQLt.TestResult;
     
    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;

    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test Run executes the SetUp for each test case in test class]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    CREATE TABLE MyTestClass.SetUpLog (SetupCalled INT);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (SetupCalled INT);
    INSERT INTO Run_Methods_Tests.SetUpLog VALUES (1);
    
    EXEC ('CREATE PROC MyTestClass.SetUp AS INSERT INTO MyTestClass.SetUpLog VALUES (1);');
    EXEC ('CREATE PROC MyTestClass.test1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    EXEC ('CREATE PROC MyTestClass.test2 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunWithNullResults 'MyTestClass';

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'MyTestClass', TestCase = 'test1', Result = 'Success' UNION ALL
    SELECT Class = 'MyTestClass', TestCase = 'test2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test Run executes the SetUp if called for single test]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    CREATE TABLE MyTestClass.SetUpLog (SetupCalled INT);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (SetupCalled INT);
    INSERT INTO Run_Methods_Tests.SetUpLog VALUES (1);
    
    EXEC ('CREATE PROC MyTestClass.SetUp AS INSERT INTO MyTestClass.SetUpLog VALUES (1);');
    EXEC ('CREATE PROC MyTestClass.test1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunWithNullResults 'MyTestClass.test1';

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'MyTestClass', TestCase = 'test1', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.test_that_a_failing_SetUp_causes_test_to_be_marked_as_failed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.SetUp AS EXEC tSQLt.Fail ''expected failure'';');
    EXEC('CREATE PROC innertest.test AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass 'innertest';
    END TRY
    BEGIN CATCH
    END CATCH

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'test' AND Result = 'Failure')
    BEGIN
       EXEC tSQLt.Fail 'failing innertest.SetUp did not cause innertest.test to fail.';
   END;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll runs all test classes created with NewTestClass]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA AS RETURN 0;');
    EXEC ('CREATE PROC B.testB AS RETURN 0;');
    EXEC ('CREATE PROC C.testC AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA' UNION ALL
    SELECT Class = 'B', TestCase = 'testB' UNION ALL
    SELECT Class = 'C', TestCase = 'testC';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll runs all test classes created with NewTestClass when there are multiple tests in each class]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA1 AS RETURN 0;');
    EXEC ('CREATE PROC A.testA2 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB1 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB2 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC1 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC2 AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA1' UNION ALL
    SELECT Class = 'A', TestCase = 'testA2' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2' UNION ALL
    SELECT Class = 'C', TestCase = 'testC1' UNION ALL
    SELECT Class = 'C', TestCase = 'testC2';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test TestResult record with Class and TestCase has Name value of quoted class name and test case name]
AS
BEGIN
    DELETE FROM tSQLt.TestResult;

    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName)
    VALUES ('MyClassName', 'MyTestCaseName', 'XYZ');
    
    SELECT Class, TestCase, Name
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
    
    INSERT INTO #Expected (Class, TestCase, Name)
    VALUES ('MyClassName', 'MyTestCaseName', '[MyClassName].[MyTestCaseName]');
    
    SELECT Class, TestCase, Name
      INTO #Actual
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll produces a test case summary]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';

    EXEC tSQLt.RunAll;

    DECLARE @CallCount INT;
    SELECT @CallCount = COUNT(1) FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    EXEC tSQLt.AssertEquals 1, @CallCount;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll clears test results between each execution]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.test1 AS RETURN 0;');

    EXEC tSQLt.RunAll;
    EXEC tSQLt.RunAll;
    
    DECLARE @NumberOfTestResults INT;
    SELECT @NumberOfTestResults = COUNT(*)
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEquals 1, @NumberOfTestResults;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run prints start and stop info when tSQLt.SetVerbose was called]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RAISERROR(''Hello'',0,1)WITH NOWAIT;');

    EXEC tSQLt.SetVerbose;
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = COL.OutputText
      FROM tSQLt.CaptureOutputLog AS COL;
     
    
    DECLARE @Expected NVARCHAR(MAX);SET @Expected =  
'tSQLt.Run ''[innertest].[testMe]''; --Starting
Hello
tSQLt.Run ''[innertest].[testMe]''; --Finished
';
      
    EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run doesn't print start and stop info when tSQLt.SetVerbose 0 was called]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RAISERROR(''Hello'',0,1)WITH NOWAIT;');

    EXEC tSQLt.SetVerbose 0;
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = COL.OutputText
      FROM tSQLt.CaptureOutputLog AS COL;
     
    
    DECLARE @Expected NVARCHAR(MAX);SET @Expected =  
'Hello
';
      
    EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROC Run_Methods_Tests.[test tSQLt.RunC calls tSQLt.Run with everything after ;-- as @TestName]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Run';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_InputBuffer', @CommandToExecute = 'SET @InputBuffer = ''EXEC tSQLt.RunC;--All this gets send to tSQLt.Run as parameter, even chars like '''',-- and []'';';

    EXEC tSQLt.RunC;

    SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('All this gets send to tSQLt.Run as parameter, even chars like '',-- and []');    
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO
CREATE PROC Run_Methods_Tests.[test tSQLt.RunC removes leading and trailing spaces from testname]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Run';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_InputBuffer', @CommandToExecute = 'SET @InputBuffer = ''EXEC tSQLt.RunC;--  XX  '';';

    EXEC tSQLt.RunC;

    SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('XX');    
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO
CREATE PROC Run_Methods_Tests.[ptest that tSQLt.Private_Run correctly captures]
  @the NVARCHAR(MAX),
  @whenTest NVARCHAR(MAX)
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');

    IF(@whenTest = 'succeeds')
    BEGIN
      EXEC('CREATE PROC innertest.testMe as EXEC tSQLt_testutil.WaitForMS 120;');
    END;
    IF(@whenTest = 'fails')
    BEGIN
      EXEC('CREATE PROC innertest.testMe as EXEC tSQLt_testutil.WaitForMS 120;EXEC tSQLt.Fail ''XX'';');
    END;

    --Prime cache to prevent unintentional "padding" of the execution time during compilation
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';'; 

    DECLARE @actual DATETIME2;
    DECLARE @after DATETIME2;
    DECLARE @before DATETIME2;

    DELETE FROM tSQLt.TestResult;
    
    SET @before = SYSDATETIME();  
    
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';
    
    SET @after = SYSDATETIME();  

    DECLARE @expectedIntervalStart DATETIME2;
    DECLARE @expectedIntervalEnd DATETIME2;

    IF(@the = 'StartTime')
    BEGIN
      SELECT  
        @actual = (SELECT TestStartTime FROM tSQLt.TestResult), 
        @expectedIntervalStart = @before,
        @expectedIntervalEnd = DATEADD(MILLISECOND, -120, @after);
    END;
    IF(@the = 'EndTime')
    BEGIN
      SELECT  
        @actual = (SELECT TestEndTime FROM tSQLt.TestResult), 
        @expectedIntervalStart = DATEADD(MILLISECOND,120,@before), 
        @expectedIntervalEnd = @after;  
    END;

    DECLARE @msg NVARCHAR(MAX);
    IF(@actual < @expectedIntervalStart OR @actual > @expectedIntervalEnd OR @actual IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),@expectedIntervalStart,121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actual,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),@expectedIntervalEnd,121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures start time]
AS
BEGIN
  EXEC Run_Methods_Tests.[ptest that tSQLt.Private_Run correctly captures] @the = 'StartTime', @whenTest = 'succeeds';
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures start time for failing test]
AS
BEGIN
  EXEC Run_Methods_Tests.[ptest that tSQLt.Private_Run correctly captures] @the = 'StartTime', @whenTest = 'fails';
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures finish time]
AS
BEGIN
  EXEC Run_Methods_Tests.[ptest that tSQLt.Private_Run correctly captures] @the = 'EndTime', @whenTest = 'succeeds';
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures finish time for failing test]
AS
BEGIN
  EXEC Run_Methods_Tests.[ptest that tSQLt.Private_Run correctly captures] @the = 'EndTime', @whenTest = 'fails';
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_GetCursorForRunNew returns all test classes created after(!) tSQLt.Reset was called]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'Test Class A';
    EXEC tSQLt.Reset;
    EXEC tSQLt.NewTestClass 'Test Class B';
    EXEC tSQLt.NewTestClass 'Test Class C';

    CREATE TABLE #TestClassesForRunCursor(Name NVARCHAR(MAX));
    EXEC tSQLt.Private_GetCursorForRunNew;
    
    SELECT TOP(0) A.* INTO #Expected FROM #TestClassesForRunCursor A RIGHT JOIN #TestClassesForRunCursor X ON 1=0;
    INSERT INTO #Expected VALUES('Test Class B');    
    INSERT INTO #Expected VALUES('Test Class C');    
     
    EXEC tSQLt.AssertEqualsTable '#Expected','#TestClassesForRunCursor';
    
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_GetCursorForRunNew skips dropped classes]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.Reset;
    EXEC tSQLt.NewTestClass 'Test Class B';
    EXEC tSQLt.NewTestClass 'Test Class C';
    EXEC tSQLt.DropClass 'Test Class C';

    CREATE TABLE #TestClassesForRunCursor(Name NVARCHAR(MAX));
    EXEC tSQLt.Private_GetCursorForRunNew;
    
    SELECT TOP(0) A.* INTO #Expected FROM #TestClassesForRunCursor A RIGHT JOIN #TestClassesForRunCursor X ON 1=0;
    INSERT INTO #Expected VALUES('Test Class B');    
     
    EXEC tSQLt.AssertEqualsTable '#Expected','#TestClassesForRunCursor';
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_RunNew calls Private_RunCursor with correct cursor]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunCursor';
  
  EXEC tSQLt.Private_RunNew @TestResultFormatter = 'A Test Result Formatter';

  SELECT TestResultFormatter,GetCursorCallback
  INTO #Actual
  FROM tSQLt.Private_RunCursor_SpyProcedureLog;
   
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('A Test Result Formatter','tSQLt.Private_GetCursorForRunNew');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler passes @TestResultFormatter to ssp]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestResultFormatter);');
  
  CREATE TABLE #Actual
  (
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]', @TestResultFormatter = 'a special formatter';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestResultFormatter) VALUES ('a special formatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler defaults @TestResultFormatter to configured Test Result Formatter]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestResultFormatter);');
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
  
  CREATE TABLE #Actual
  (
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestResultFormatter) VALUES ('CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Private_RunMethodHandler passes @TestName if ssp has that parameter]
AS
BEGIN
  CREATE TABLE #Actual
  (
     TestName NVARCHAR(MAX),
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestName NVARCHAR(MAX), @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestName,@TestResultFormatter);');
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
  
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]', @TestName = 'some test';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestName, TestResultFormatter) VALUES ('some test','CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler calls Private_Init before calling ssp]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(''run method'');');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Init', @CommandToExecute = 'INSERT #Actual VALUES(''Private_Init'');';
  
  CREATE TABLE #Actual
  (
     Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
     Method NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1,'Private_Init');
  INSERT INTO #Expected VALUES (2,'run method');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunAll calls Private_RunMethodHandler with tSQLt.Private_RunAll]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunMethodHandler';

  EXEC tSQLt.RunAll;

  SELECT RunMethod
  INTO #Actual
  FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES ('tSQLt.Private_RunAll');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunNew calls Private_RunMethodHandler with tSQLt.Private_RunNew]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunMethodHandler';

  EXEC tSQLt.RunNew;

  SELECT RunMethod
  INTO #Actual
  FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES ('tSQLt.Private_RunNew');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Run calls Private_RunMethodHandler correctly]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunMethodHandler';
 
  EXEC tSQLt.Run @TestName = 'some test', @TestResultFormatter = 'some special formatter';
  
  SELECT RunMethod, TestResultFormatter, TestName
    INTO #Actual
    FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected (RunMethod, TestResultFormatter, TestName)VALUES('tSQLt.Private_Run', 'some special formatter', 'some test');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test PrepareTestResultForOutput calculates test duration]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
                                 
  EXEC('                                                                                    
  INSERT INTO tSQLt.TestResult(Name,TestStartTime,TestEndTime)
  VALUES(''[a test class].[test 1]'',''2015-07-18T00:00:01.000'',''2015-07-18T00:10:10.555'');
  INSERT INTO tSQLt.TestResult(Name,TestStartTime,TestEndTime)
  VALUES(''[a test class].[test 2]'',''2015-07-18T00:00:02.000'',''2015-07-18T00:22:03.444'');
  ');

  SELECT PTRFO.[Test Case Name],
         PTRFO.[Dur(ms)]
    INTO #Actual
    FROM tSQLt.Private_PrepareTestResultForOutput() AS PTRFO

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('[a test class].[test 1]',' 609555'),
        ('[a test class].[test 2]','1321444');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROC Run_Methods_Tests.[test PrepareTestResultForOutput orders tests appropriately]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 4]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 7]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 9]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 5]'',''Skipped'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 6]'',''Error'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Error'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 8]'',''Skipped'');
  ');

  SELECT 
      PTRFO.No,
      PTRFO.[Test Case Name],
      PTRFO.Result
    INTO #Actual
    FROM tSQLt.Private_PrepareTestResultForOutput() AS PTRFO

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1,'[a test class].[test 1]','Success'),
        (2,'[a test class].[test 3]','Success'),
        (3,'[a test class].[test 7]','Success'),
        (4,'[a test class].[test 5]','Skipped'),
        (5,'[a test class].[test 8]','Skipped'),
        (6,'[a test class].[test 4]','Failure'),
        (7,'[a test class].[test 9]','Failure'),
        (8,'[a test class].[test 2]','Error'),
        (9,'[a test class].[test 6]','Error');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE FUNCTION Run_Methods_Tests.[Returns 7,SomeSpecificName,42,Failure]()
RETURNS TABLE
AS
RETURN
  SELECT 7 No,'SomeSpecificName' [Test Case Name],42 [Dur(ms)], 'Failure' Result;
GO
CREATE PROC Run_Methods_Tests.[test DefaultResultFormatter is using PrepareTestResultForOutput]
AS
BEGIN
 EXEC tSQLt.FakeFunction 
   @FunctionName = 'tSQLt.Private_PrepareTestResultForOutput', 
   @FakeFunctionName = 'Run_Methods_Tests.[Returns 7,SomeSpecificName,42,Failure]';

 EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';

 EXEC tSQLt.DefaultResultFormatter;
  
 EXEC tSQLt_testutil.AssertTableContainsString 
         @Table = 'tSQLt.Private_Print_SpyProcedureLog',
         @Column = 'Message',
         @Pattern = '%7%SomeSpecificName%42%Failure%';

END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with multiple test elements some skipped]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Skipped', 'testA intentionally skipped');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Skipped', 'testC intentionally skipped');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Success', NULL);
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT TestCase.value('@name','NVARCHAR(MAX)') AS TestCase, TestCase.value('skipped[1]/@message','NVARCHAR(MAX)') AS Msg
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TestCase,Msg
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter sets correct counts for skipped tests]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Skipped');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass2', 'testE', 'XYZ', 'Failure');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass3', 'testF', 'XYZ', 'Skipped');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass3', 'testG', 'XYZ', 'Error');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass3', 'testH', 'XYZ', 'Skipped');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass3', 'testI', 'XYZ', 'Skipped');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS Tests,
      TestCase.value('@skipped','NVARCHAR(MAX)') AS Skipped
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
--    SELECT * FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    
    SELECT *
    INTO #expected
    FROM (
      SELECT N'MyTestClass1' AS Class, 2 Tests, 0 Skipped
      UNION ALL
      SELECT N'MyTestClass2' AS Class, 3 Tests, 1 Skipped
      UNION ALL
      SELECT N'MyTestClass3' AS Class, 4 Tests, 3 Skipped
    ) AS x;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE Run_Methods_Tests.SetupXMLSchemaCollection
AS
BEGIN
--Valid JUnit XML Schema
--Source:https://raw.githubusercontent.com/windyroad/JUnit-Schema/master/JUnit.xsd
--Source with commit-id: https://raw.githubusercontent.com/windyroad/JUnit-Schema/d6daa414c448da22b810c8562f9d6fca086983ba/JUnit.xsd
DECLARE @cmd NVARCHAR(MAX);SET @cmd = 
'<?xml version="1.0" encoding="UTF-8"?>
<xs:schema
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	 elementFormDefault="qualified"
	 attributeFormDefault="unqualified">
	<xs:annotation>
		<xs:documentation xml:lang="en">JUnit test result schema for the Apache Ant JUnit and JUnitReport tasks
Copyright � 2011, Windy Road Technology Pty. Limited
The Apache Ant JUnit XML Schema is distributed under the terms of the Apache License Version 2.0 http://www.apache.org/licenses/
Permission to waive conditions of this license may be requested from Windy Road Support (http://windyroad.org/support).</xs:documentation>
	</xs:annotation>
	<xs:element name="testsuite" type="testsuite"/>
	<xs:simpleType name="ISO8601_DATETIME_PATTERN">
		<xs:restriction base="xs:dateTime">
			<xs:pattern value="[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"/>
		</xs:restriction>
	</xs:simpleType>
	<xs:element name="testsuites">
		<xs:annotation>
			<xs:documentation xml:lang="en">Contains an aggregation of testsuite results</xs:documentation>
		</xs:annotation>
		<xs:complexType>
			<xs:sequence>
				<xs:element name="testsuite" minOccurs="0" maxOccurs="unbounded">
					<xs:complexType>
						<xs:complexContent>
							<xs:extension base="testsuite">
								<xs:attribute name="package" type="xs:token" use="required">
									<xs:annotation>
										<xs:documentation xml:lang="en">Derived from testsuite/@name in the non-aggregated documents</xs:documentation>
									</xs:annotation>
								</xs:attribute>
								<xs:attribute name="id" type="xs:int" use="required">
									<xs:annotation>
										<xs:documentation xml:lang="en">Starts at ''0'' for the first testsuite and is incremented by 1 for each following testsuite</xs:documentation>
									</xs:annotation>
								</xs:attribute>
							</xs:extension>
						</xs:complexContent>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:complexType name="testsuite">
		<xs:annotation>
			<xs:documentation xml:lang="en">Contains the results of exexuting a testsuite</xs:documentation>
		</xs:annotation>
		<xs:sequence>
			<xs:element name="properties">
				<xs:annotation>
					<xs:documentation xml:lang="en">Properties (e.g., environment settings) set during test execution</xs:documentation>
				</xs:annotation>
				<xs:complexType>
					<xs:sequence>
						<xs:element name="property" minOccurs="0" maxOccurs="unbounded">
							<xs:complexType>
								<xs:attribute name="name" use="required">
									<xs:simpleType>
										<xs:restriction base="xs:token">
											<xs:minLength value="1"/>
										</xs:restriction>
									</xs:simpleType>
								</xs:attribute>
								<xs:attribute name="value" type="xs:string" use="required"/>
							</xs:complexType>
						</xs:element>
					</xs:sequence>
				</xs:complexType>
			</xs:element>
			<xs:element name="testcase" minOccurs="0" maxOccurs="unbounded">
				<xs:complexType>
					<xs:choice minOccurs="0">
						<xs:element name="skipped" />
						<xs:element name="error" minOccurs="0" maxOccurs="1">
							<xs:annotation>
								<xs:documentation xml:lang="en">Indicates that the test errored.  An errored test is one that had an unanticipated problem. e.g., an unchecked throwable; or a problem with the implementation of the test. Contains as a text node relevant data for the error, e.g., a stack trace</xs:documentation>
							</xs:annotation>
							<xs:complexType>
								<xs:simpleContent>
									<xs:extension base="pre-string">
										<xs:attribute name="message" type="xs:string">
											<xs:annotation>
												<xs:documentation xml:lang="en">The error message. e.g., if a java exception is thrown, the return value of getMessage()</xs:documentation>
											</xs:annotation>
										</xs:attribute>
										<xs:attribute name="type" type="xs:string" use="required">
											<xs:annotation>
												<xs:documentation xml:lang="en">The type of error that occured. e.g., if a java execption is thrown the full class name of the exception.</xs:documentation>
											</xs:annotation>
										</xs:attribute>
									</xs:extension>
								</xs:simpleContent>
							</xs:complexType>
						</xs:element>
						<xs:element name="failure">
							<xs:annotation>
								<xs:documentation xml:lang="en">Indicates that the test failed. A failure is a test which the code has explicitly failed by using the mechanisms for that purpose. e.g., via an assertEquals. Contains as a text node relevant data for the failure, e.g., a stack trace</xs:documentation>
							</xs:annotation>
							<xs:complexType>
								<xs:simpleContent>
									<xs:extension base="pre-string">
										<xs:attribute name="message" type="xs:string">
											<xs:annotation>
												<xs:documentation xml:lang="en">The message specified in the assert</xs:documentation>
											</xs:annotation>
										</xs:attribute>
										<xs:attribute name="type" type="xs:string" use="required">
											<xs:annotation>
												<xs:documentation xml:lang="en">The type of the assert.</xs:documentation>
											</xs:annotation>
										</xs:attribute>
									</xs:extension>
								</xs:simpleContent>
							</xs:complexType>
						</xs:element>
					</xs:choice>
					<xs:attribute name="name" type="xs:token" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Name of the test method</xs:documentation>
						</xs:annotation>
					</xs:attribute>
					<xs:attribute name="classname" type="xs:token" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Full class name for the class the test method is in.</xs:documentation>
						</xs:annotation>
					</xs:attribute>
					<xs:attribute name="time" type="xs:decimal" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Time taken (in seconds) to execute the test</xs:documentation>
						</xs:annotation>
					</xs:attribute>
				</xs:complexType>
			</xs:element>
			<xs:element name="system-out">
				<xs:annotation>
					<xs:documentation xml:lang="en">Data that was written to standard out while the test was executed</xs:documentation>
				</xs:annotation>
				<xs:simpleType>
					<xs:restriction base="pre-string">
						<xs:whiteSpace value="preserve"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:element>
			<xs:element name="system-err">
				<xs:annotation>
					<xs:documentation xml:lang="en">Data that was written to standard error while the test was executed</xs:documentation>
				</xs:annotation>
				<xs:simpleType>
					<xs:restriction base="pre-string">
						<xs:whiteSpace value="preserve"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:element>
		</xs:sequence>
		<xs:attribute name="name" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Full class name of the test for non-aggregated testsuite documents. Class name without the package for aggregated testsuites documents</xs:documentation>
			</xs:annotation>
			<xs:simpleType>
				<xs:restriction base="xs:token">
					<xs:minLength value="1"/>
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="timestamp" type="ISO8601_DATETIME_PATTERN" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">when the test was executed. Timezone may not be specified.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="hostname" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Host on which the tests were executed. ''localhost'' should be used if the hostname cannot be determined.</xs:documentation>
			</xs:annotation>
			<xs:simpleType>
				<xs:restriction base="xs:token">
					<xs:minLength value="1"/>
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="tests" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="failures" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite that failed. A failure is a test which the code has explicitly failed by using the mechanisms for that purpose. e.g., via an assertEquals</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="errors" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite that errored. An errored test is one that had an unanticipated problem. e.g., an unchecked throwable; or a problem with the implementation of the test.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="skipped" type="xs:int" use="optional">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of ignored or skipped tests in the suite.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="time" type="xs:decimal" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Time taken (in seconds) to execute the tests in the suite</xs:documentation>
			</xs:annotation>
		</xs:attribute>
	</xs:complexType>
	<xs:simpleType name="pre-string">
		<xs:restriction base="xs:string">
			<xs:whiteSpace value="preserve"/>
		</xs:restriction>
	</xs:simpleType>
</xs:schema>';
SET @cmd = 'CREATE XML SCHEMA COLLECTION Run_Methods_Tests.ValidJUnitXML AS '''+REPLACE(REPLACE(@cmd,'''',''''''),'�','(c)')+''';';
--EXEC(@cmd);
EXEC tSQLt.CaptureOutput @cmd;
END;
GO
--[@tSQLt:MinSqlMajorVersion](10)
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter returns XML that validates against the JUnit test result xsd]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138','failed intentionally');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:02.000', '2015-07-24T00:00:02.633',NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-07-24T20:31:24.758','failed intentionally');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:00.667', '2015-07-24T00:00:01.055','errored intentionally');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass2', 'testE', 'Skipped', '2015-07-24T00:00:01.111', '2015-07-24T20:31:24.758','skipped intentionally');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime,Msg)
    VALUES ('MyTestClass2', 'testF', 'Skipped', '2015-07-24T00:00:00.667', '2015-07-24T00:00:01.055','skipped intentionally');
    
    EXEC tSQLt.XmlResultFormatter;

    EXEC tSQLt.ExpectNoException;
RETURN
    EXEC Run_Methods_Tests.SetupXMLSchemaCollection;
    DECLARE @TestResultXML XML;
    SELECT @TestResultXML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    -- The assignment below will fail if the @TestResultXML is not schema conform
    EXEC sp_executesql N'DECLARE @TestSchema XML(Run_Methods_Tests.ValidJUnitXML) = @TestResultXML',N'@TestResultXML XML',@TestResultXML;
END;
GO
--[@tSQLt:MinSqlMajorVersion](10)
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Private_InputBuffer does not produce output]
AS
BEGIN
  DECLARE @Actual NVARCHAR(MAX);SET @Actual = '<Something went wrong!>';

  EXEC tSQLt.CaptureOutput 'DECLARE @r NVARCHAR(MAX);EXEC tSQLt.Private_InputBuffer @r OUT;';

  SELECT @Actual  = COL.OutputText FROM tSQLt.CaptureOutputLog AS COL;
  
  EXEC tSQLt.AssertEqualsString @Expected = NULL, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is "printed" as error if there is one error result]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Error'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 4]'',''Skipped'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Test Case Summary:%';
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is "printed" as error if there is one failure result]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 4]'',''Skipped'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Test Case Summary:%';
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is "printed" as error if there are multiple failure and error results]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Error'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 4]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 5]'',''Skipped'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 6]'',''Error'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 7]'',''Failure'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 8]'',''Success'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Test Case Summary:%';
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is not "printed" as error if there are only success results]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Success'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is not "printed" as error if there are only skipped results]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Skipped'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Skipped'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Skipped'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test the Test Case Summary line is not "printed" as error if there are only success and skipped results]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  EXEC('
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 1]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 2]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 3]'',''Success'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 4]'',''Skipped'');
    INSERT INTO tSQLt.TestResult(Name,Result)VALUES(''[a test class].[test 5]'',''Skipped'');
  ');

  EXEC tSQLt.SetSummaryError @SummaryError = 1; --Global setting to actually raise an error -- the build is turning this off

  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.DefaultResultFormatter;

END
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Private_InputBuffer returns non-empty string]
AS
BEGIN
  DECLARE @r NVARCHAR(MAX);EXEC tSQLt.Private_InputBuffer @r OUT;
  IF(ISNULL(@r,'') = '')
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.Private_InputBuffer returned NULL or an empty string.';
  END;
END
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunAll can handle classes with single quotes]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunTestClass';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestClasses';
  EXEC('INSERT INTO tSQLt.TestClasses VALUES(''a class with a '''' in the middle'',12321);');

  EXEC tSQLt.RunAll;

  SELECT TestClassName
  INTO #Actual
  FROM tSQLt.Private_RunTestClass_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES ('a class with a '' in the middle');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/* ----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunAll executes tests with single quotes in class and name]
AS
BEGIN
  CREATE TABLE #Actual (Id INT);
  EXEC ('CREATE SCHEMA [a class with a '' in the middle];');
  EXEC ('
  --[@'+'tSQLt:NoTransaction](DEFAULT)
  CREATE PROCEDURE [a class with a '' in the middle].[test with a '' in the middle] AS BEGIN INSERT INTO #Actual VALUES (1); END;
  ');

  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestClasses';
  EXEC('INSERT INTO tSQLt.TestClasses VALUES(''a class with a '''' in the middle'',12321);');

  EXEC tSQLt.SetSummaryError 0;

  EXEC tSQLt.RunAll;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/* ----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunTestClass executes tests with single quotes in class and name]
AS
BEGIN
  CREATE TABLE #Actual (Id INT);
  EXEC ('CREATE SCHEMA [a class with a '' in the middle];');
  EXEC ('
  --[@'+'tSQLt:NoTransaction](DEFAULT)
  CREATE PROCEDURE [a class with a '' in the middle].[test with a '' in the middle] AS BEGIN INSERT INTO #Actual VALUES (1); END;
  ');

  EXEC tSQLt.RunTestClass @TestClassName = '[a class with a '' in the middle]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/* ----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Run executes test class with single quotes in name]
AS
BEGIN
  CREATE TABLE #Actual (Id INT);
  EXEC ('CREATE SCHEMA [a class with a '' in the middle];');
  EXEC ('
  --[@'+'tSQLt:NoTransaction](DEFAULT)
  CREATE PROCEDURE [a class with a '' in the middle].[test with a '' in the middle] AS BEGIN INSERT INTO #Actual VALUES (1); END;
  ');

  EXEC tSQLt.Run '[a class with a '' in the middle]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/* ----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Run executes test with single quotes in class and test names]
AS
BEGIN
  CREATE TABLE #Actual (Id INT);
  EXEC ('CREATE SCHEMA [a class with a '' in the middle];');
  EXEC ('
  --[@'+'tSQLt:NoTransaction](DEFAULT)
  CREATE PROCEDURE [a class with a '' in the middle].[test with a '' in the middle] AS BEGIN INSERT INTO #Actual VALUES (1); END;
  ');

  EXEC tSQLt.Run '[a class with a '' in the middle].[test with a '' in the middle]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/* ----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunNew executes test class with single quotes in class and test names]
AS
BEGIN
  CREATE TABLE #Actual (Id INT);
  EXEC ('CREATE SCHEMA [a class with a '' in the middle];');
  EXEC ('
  --[@'+'tSQLt:NoTransaction](DEFAULT)
  CREATE PROCEDURE [a class with a '' in the middle].[test with a '' in the middle] AS BEGIN INSERT INTO #Actual VALUES (1); END;
  ');
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestClasses';

  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';

  EXEC('INSERT INTO tSQLt.TestClasses(Name) VALUES(''a class with a '''' in the middle'');');
  EXEC('INSERT INTO tSQLt.Private_NewTestClassList(ClassName) VALUES(''a class with a '''' in the middle'');');

  EXEC tSQLt.SetSummaryError 0;

  EXEC tSQLt.RunNew;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test FATAL error prevents subsequent tSQLt.Run% calls]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables', @CommandToExecute = 'IF(@Action = ''Reset'')BEGIN RAISERROR(''Some Fatal Error'',16,10);END;';

  BEGIN TRY
    EXEC tSQLt.Run 'MyInnerTests', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
  END TRY
  BEGIN CATCH
    /* not interested in this error */
  END CATCH;
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an invalid state. Please reinstall tSQLt.';
  EXEC tSQLt.Run 'MyInnerTests', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test when @Result=FATAL an appropriate error message is raised]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables', @CommandToExecute = 'IF(@Action = ''Reset'')BEGIN RAISERROR(''Some Fatal Error'',16,10);END;';

  EXEC tSQLt.SetSummaryError @SummaryError = 1;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'The last test has invalidated the current installation of tSQLt. Please reinstall tSQLt.';
  EXEC tSQLt.Run 'MyInnerTests';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Run_Methods_Tests.[test when @Result=Abort an appropriate error message is raised]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles', @CommandToExecute = 'RAISERROR(''Some Fatal Error'',16,10);';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';

  EXEC tSQLt.SetSummaryError @SummaryError = 1;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Aborting the current execution of tSQLt due to a severe error.';
  EXEC tSQLt.Run 'MyInnerTests';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Run_Methods_Tests.[test produces meaningful error when pre and post transactions counts don't match]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTestsA'
  EXEC('CREATE PROCEDURE MyInnerTestsA.[test should execute outside of transaction] AS BEGIN TRAN;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;
  EXEC tSQLt.Run 'MyInnerTestsA.[test should execute outside of transaction]';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

--[@tSQLt:SkipTest]('TODO: need to review handling of unexpected changes to the tSQLt transaction for NoTransaction tests')
CREATE PROCEDURE Run_Methods_Tests.[test produces meaningful error when pre and post transactions counts don't match in NoTransaction test]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTestsB'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTestsB.[test should execute outside of transaction] AS BEGIN TRAN;SELECT * FROM fn_dblog(NULL,NULL) WHERE [Transaction ID] = (SELECT LL.[Transaction ID] FROM fn_dblog(NULL,NULL) LL JOIN sys.dm_tran_current_transaction AS DTCT ON DTCT.transaction_id = LL.[Xact ID]);
  ');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;

  BEGIN TRY
    EXEC tSQLt.Run 'MyInnerTestsB.[test should execute outside of transaction]';
  END TRY
  BEGIN CATCH
    SELECT * FROM fn_dblog(NULL,NULL) WHERE [Transaction ID] = (SELECT LL.[Transaction ID] FROM fn_dblog(NULL,NULL) LL JOIN sys.dm_tran_current_transaction AS DTCT ON DTCT.transaction_id = LL.[Xact ID]);
  END CATCH;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
/*--
  Transaction Tests
  
  - NoTransaction, but suddenly has transaction
  - with transaction, but creates additional transaction
  - transaction, but is committed (FATAL)
  - what should we do if the original transaction was rolled back and a new one was created?
  - what should we do if the original transaction was committed and a new one was created?
  - we still need to save the TranName as something somewhere.
  - do existing tests already cover some of the scenarios described above?

--*/
