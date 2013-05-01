EXEC tSQLt.NewTestClass 'Run_Methods_Tests';
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

CREATE PROC Run_Methods_Tests.[test RunTestClass raises error if error in default print mode]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.DefaultResultsFormatter';
    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS RETURN 1/0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass MyTestClass;
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    IF(@ErrorRaised = 0)
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not raise an error!';
    END
END;
GO

CREATE PROC Run_Methods_Tests.test_Run_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RAISERROR(''GotHere'',16,10);');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.Test Case A';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Msg 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase, 'GotHere{Test Case A,1}' Msg
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run executes all tests in test class when called with class name]
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

CREATE PROC tSQLt_test.[test that tSQLt.Run executes single test when called with test case name]
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

CREATE PROC tSQLt_test.[test that tSQLt.Run re-executes single test when called without parameter]
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

CREATE PROC tSQLt_test.[test that tSQLt.Run re-executes testClass when called without parameter]
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

CREATE PROC tSQLt_test.[test that tSQLt.Run deletes all entries from tSQLt.Run_LastExecution with same SPID]
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

CREATE PROC tSQLt_test.test_RunTestClass_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RETURN 0;');

    EXEC tSQLt.RunTestClass MyTestClass;
    
    SELECT Class, TestCase 
      INTO actual
      FROM tSQLt.TestResult;
      
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Run executes a test class even if there is a dbo owned object of the same name]
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

CREATE PROCEDURE tSQLt_test.[test Run calls Private_Run with configured Test Result Formatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt', @ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
 
  EXEC tSQLt.Run 'SomeTest';
  
  SELECT TestName, TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected (TestName, TestResultFormatter)VALUES('SomeTest', 'CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_Run calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  
  EXEC tSQLt.Private_Run 'NoTestSchema.NoTest','SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_OutputTestResults uses the TestResultFormatter parameter]
AS
BEGIN
  EXEC('CREATE PROC tSQLt_test.TemporaryTestResultFormatter AS RAISERROR(''GotHere'',16,10);');
  
  BEGIN TRY
    EXEC tSQLt.Private_OutputTestResults 'tSQLt_test.TemporaryTestResultFormatter';
  END TRY
  BEGIN CATCH
    IF(ERROR_MESSAGE() LIKE '%GotHere%') RETURN 0;
  END CATCH
  EXEC tSQLt.Fail 'tSQLt_test.TemporaryTestResultFormatter did not get called correctly';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunAll calls Private_RunAll with configured Test Result Formatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunAll';
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
 
  EXEC tSQLt.RunAll;
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_RunAll_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter) VALUES ('CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_RunAll calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
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

CREATE PROCEDURE tSQLt_test.[test RunWithXmlResults calls Private_Run with XmlTestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithXmlResults 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.XmlResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunWithXmlResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithXmlResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test NullTestResultFormatter prints no results from the tests]
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

CREATE PROC tSQLt_test.[test procedure can be injected to display test results]
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

CREATE PROC tSQLt_test.[test XmlResultFormatter creates <testsuites/> when no test cases in test suite]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with test element when there is a passing test]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter handles even this:   ,/?'';:[o]]}\|{)(*&^%$#@""]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with test element and failure element when there is a failing test]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with multiple test elements some with failures]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with multiple test elements some with failures or errors]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter sets correct counts in testsuite attributes]
AS
BEGIN
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

CREATE PROC tSQLt_test.[test XmlResultFormatter arranges multiple test cases into testsuites]
AS
BEGIN
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

CREATE PROCEDURE tSQLt_test.[test RunWithNullResults calls Private_Run with NullTestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithNullResults 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.NullTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunWithNullResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithNullResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
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
