EXEC tSQLt.NewTestClass 'AnnotationNoTransactionTests';
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test runs test without transaction]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS INSERT INTO #TranCount VALUES(''I'',@@TRANCOUNT);;
  ');

  SELECT 'B' Id, @@TRANCOUNT TranCount
    INTO #TranCount;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';

  INSERT INTO #TranCount VALUES('A',@@TRANCOUNT);

  SELECT Id, TranCount-MIN(TranCount)OVER() AdjustedTrancount
    INTO #Actual
    FROM #TranCount;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('B',0),('I',0),('A',0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO: needs other tests first')
CREATE PROCEDURE AnnotationNoTransactionTests.[test produces meaningful error when pre and post transactions counts don't match]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS BEGIN TRAN;
  ');

  --EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test transaction name is NULL in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RETURN;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT TranName INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(NULL);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test if not NoTransaction TranName is valued in TestResults table]
AS
BEGIN
  DECLARE @ActualTranName NVARCHAR(MAX);
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test should execute inside of transaction] AS RETURN;');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute inside of transaction]';
  SET @ActualTranName = (SELECT TranName FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = 'tSQLtTran%', @Actual = @ActualTranName;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test succeeding test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RETURN;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Success');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test failing test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS EXEC tSQLt.Fail ''Some Obscure Reason'';
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Failure','Some Obscure Reason');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test recoverable erroring test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RAISERROR (''Some Obscure Recoverable Error'', 16, 10);
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Error','Some Obscure Recoverable Error[16,10]{MyInnerTests.test should execute outside of transaction,3}');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls tSQLt.Private_CleanUp]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT FullTestName INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('[MyInnerTests].[test1]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and succeeding]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and failing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS EXEC tSQLt.Fail;');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and erroring]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS RAISERROR(''X'',16,10);');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is appended to tSQLt.TestResult.Msg]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS PRINT 1/0;
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is called before the test result message is printed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS RAISERROR(''<In-Test-Error>'',16,10);
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Message FROM tSQLt.Private_Print_SpyProcedureLog WHERE Message LIKE '%<In-Test-Error>%');

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt tables are backed up before test is executed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual SELECT Action FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  SELECT Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('Save');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test using SkipTest and NoTransaction annotation skips the test]
AS
BEGIN
  CREATE TABLE #SkippedTestExecutionLog (Id INT);
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    --[@'+'tSQLt:SkipTest]('')
    CREATE PROCEDURE MyInnerTests.[skippedTest]
    AS
    BEGIN
      INSERT INTO #SkippedTestExecutionLog VALUES (1);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[skippedTest]';

  EXEC tSQLt.AssertEmptyTable @TableName = '#SkippedTestExecutionLog';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call 'Save' if @NoTransactionFlag=0;]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual SELECT Action FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  SELECT TOP(0) Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_NoTransactionHandleTables if @NoTransactionFlag=1 and @SkipTestFlag=1]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';

  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    --[@'+'tSQLt:SkipTest]('''')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[Redact IsTestObject status on all objects]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  WITH MarkedTestDoubles AS
  (
    SELECT 
        TempO.Name,
        SCHEMA_NAME(TempO.schema_id) SchemaName,
        TempO.type ObjectType
      FROM sys.tables TempO
      JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = TempO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
  )
  SELECT @cmd = 
  (
    SELECT 
        'EXEC sp_updateextendedproperty ''tSQLt.IsTempObject'',-1342,''SCHEMA'', '''+MTD.SchemaName+''', ''TABLE'', '''+MTD.Name+''';'  
      FROM MarkedTestDoubles MTD
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[Restore IsTestObject status on all objects]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  WITH MarkedTestDoubles AS
  (
    SELECT 
        TempO.Name,
        SCHEMA_NAME(TempO.schema_id) SchemaName,
        TempO.type ObjectType
      FROM sys.tables TempO
      JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = TempO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = -1342
  )
  SELECT @cmd = 
  (
    SELECT 
        'EXEC sp_updateextendedproperty ''tSQLt.IsTempObject'',1,''SCHEMA'', '''+MTD.SchemaName+''', ''TABLE'', '''+MTD.Name+''';'  
      FROM MarkedTestDoubles MTD
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO
CREATE FUNCTION AnnotationNoTransactionTests.PassThrough(@TestName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT @TestName TestName
GO
--[@tSQLt:NoTransaction](DEFAULT)
--[@tSQLt:SkipTest]('')
/* This test must be NoTransaction because the inner test will invalidate any open transaction causing chaos and turmoil in the reactor. */
CREATE PROCEDURE AnnotationNoTransactionTests.[test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_GetLastTestNameIfNotProvided', @FakeFunctionName = 'AnnotationNoTransactionTests.PassThrough'; /* --<-- Prevent tSQLt-internal turmoil */
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SaveTestNameForSession';/* --<-- Prevent tSQLt-internal turmoil */
  EXEC ('CREATE SCHEMA MyInnerTests AUTHORIZATION [tSQLt.TestClass];');
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should cause unrecoverable error] AS PRINT CAST(''Some obscure string'' AS INT);
  ');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'IF(@FullTestName <> ''[MyInnerTests].[test should cause unrecoverable error]'')BEGIN EXEC tSQLt.Private_NoTransactionHandleTables @Action=''Reset'';EXEC tSQLt.UndoTestDoubles @Force = 0;END;';
  EXEC tSQLt.SetSummaryError 0;

  EXEC tSQLt.Run 'MyInnerTests.[test should cause unrecoverable error]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT Name, Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('[MyInnerTests].[test should cause unrecoverable error]', 'Error','Conversion failed when converting the varchar value ''Some obscure string'' to data type int.[16,1]{MyInnerTests.test should cause unrecoverable error,3}');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('')
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls user supplied clean up procedure after test completes]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserCleanUp1'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp1]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));


  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'UserCleanUp1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO


/*-- TODO

 CLEANUP: named cleanup x 3 (needs to execute even if there's an error during test execution)
- there will be three clean up methods, executed in the following order
- 1. User defined clean up for an individual test as specified in the NoTransaction annotation parameter
- 1.a [<TESTCLASS>].[<TESTNAME>.CleanUp]
- 1.b --[@tSQLt:NoTransaction]('[<SCHEMANAME>].[<SPNAME>]')
--[@tSQLt:NoTransaction](DEFAULT)
- 2. User defined clean up for a test class as specified by [<TESTCLASS>].CleanUp
- 3. tSQLt.Private_CleanUp
- Errors thrown in any of the CleanUp methods are captured and causes the test @Result to be set to Error
- If a previous CleanUp method errors or fails, it does not cause any following CleanUps to be skipped.
- appropriate error messages are appended to the test msg 

- tSQLt.SpyProcedure needs a "call original" option
- test that the three cleanups are running in the correct order. might need ^^ to wrok. (duplicate of line 455)

Transactions
- transaction opened during test
- transaction commited during test
- inner-transaction-free test errors with uncommittable transaction
- confirm pre and post transaction counts match
- [test produces meaningful error when pre and post transactions counts don't match]
-  we still need to save the TranName as something somewhere.

SkipTest Annotation & NoTransaction Annotation
- The test is skipped
- No other objects are dropped or created
- No handler is called
- Transaction something something <-- this!

Everything is being called in the right order.
- test for execution in the correct place in Private_RunTest, after the outer-most test execution try catch
- Make sure undotestdoubles and handletables are called in the right order


--*/