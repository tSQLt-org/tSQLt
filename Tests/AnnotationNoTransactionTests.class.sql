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
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp is executed]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp is not called if test is not annotated and passing]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp is not called if test is not annotated and failing]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp is not called if test is not annotated and erroring]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp error message is appended to tSQLt.TestResult.Msg]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS PRINT 1/0;
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt.Private_CleanUp is called before the test result message is printed]
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
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';

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
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';
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
CREATE PROCEDURE AnnotationNoTransactionTests.[CLEANUP: test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.SetSummaryError 1;
  EXEC tSQLt.DropClass MyInnerTests;
  --EXEC tSQLt.UndoTestDoubles;
  --ROLLBACK
END;
GO
---[@tSQLt:SkipTest]('')
--[@tSQLt:NoTransaction]('AnnotationNoTransactionTests.[CLEANUP: test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]')
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

  /*******************************************************************************************************************************/
  /************************* MESSING WITH THIS CODE WILL PUT tSQLt INTO AN INVALID STATE! ****************************************/
  /**/CREATE TABLE #CleanUpProcedures_StopExecutionForInnerTests(I INT);
  /**/EXEC tSQLt.SpyProcedure 
  /**/       @ProcedureName = 'tSQLt.Private_CleanUp', 
  /**/       @CommandToExecute = 'IF(OBJECT_ID(''tempdb..#CleanUpProcedures_StopExecutionForInnerTests'')IS NOT NULL)BEGIN RETURN;END;', 
  /**/       @CallOriginal = 1;
  /**/EXEC tSQLt.SpyProcedure 
  /**/       @ProcedureName = 'tSQLt.Private_AssertNoSideEffects', 
  /**/       @CommandToExecute = 'IF(OBJECT_ID(''tempdb..#CleanUpProcedures_StopExecutionForInnerTests'')IS NOT NULL)BEGIN RETURN;END;', 
  /**/       @CallOriginal = 1;
  /************************* MESSING WITH THIS CODE WILL PUT tSQLt INTO AN INVALID STATE! ****************************************/
  /*******************************************************************************************************************************/

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
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed after test completes]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed even if it has a single quote in its name and/or its schema name]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInner''Tests'
  EXEC('
    CREATE PROCEDURE [MyInner''Tests].[UserClean''Up1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserClean''''Up1'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInner''''Tests].[UserClean''''Up1]'')
    CREATE PROCEDURE [MyInner''Tests].[test''1]
    AS
    BEGIN
      RETURN
    END;
  ');

  CREATE TABLE #Actual (col1 NVARCHAR(MAX));


  EXEC tSQLt.Run '[MyInner''Tests].[test''1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('UserClean''Up1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test annotation throws appropriate error if specified Test-CleanUp does not exist]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUpDoesNotExist]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');

  
  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name,
         TR.Result,
         TR.Msg
    INTO #Actual
    FROM tSQLt.TestResult AS TR

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES (
        '[MyInnerTests].[test1]',
        'Error', 
        'There is a problem with this annotation: [@tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUpDoesNotExist]'')
Original Error: {16,10;(null)} Test CleanUp Procedure [MyInnerTests].[UserCleanUpDoesNotExist] does not exist or is not a procedure.')
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test annotation throws appropriate error if specified Test-CleanUp is not a procedure]

AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE VIEW [MyInnerTests].[NotAProcedure] AS SELECT 1 X;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[NotAProcedure]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult AS TR);
  EXEC tSQLt.AssertLike @ExpectedPattern = '%Test CleanUp Procedure [[]MyInnerTests].[[]NotAProcedure] does not exist or is not a procedure.', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test annotation does not throw error if specified Test-CleanUp is a CLR stored procedure]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](''tSQLt_testutil.AClrSsp'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');
  EXEC tSQLt.SetSummaryError @SummaryError = 1;

  EXEC tSQLt.ExpectNoException;
  
  EXEC tSQLt.Run 'MyInnerTests.[test1]'--, @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt executes multiple Test-CleanUp in the order they are specified]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp7] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp7''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp3] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp3''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp9] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp9''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp7'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp3'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp9'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'CleanUp7'),(3, 'CleanUp3'), (4, 'CleanUp9');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed after Test-CleanUp]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[TestCleanUp] AS BEGIN INSERT INTO #Actual VALUES (''TestCleanUp''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp] AS BEGIN INSERT INTO #Actual VALUES (''(Schema)CleanUp''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.TestCleanUp'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'TestCleanUp'),(3, '(Schema)CleanUp');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed only if it is a stored procedure]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE VIEW [MyInnerTests].[CleanUp] AS SELECT 1 X;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.ExpectNoException;
  
  EXEC tSQLt.Run 'MyInnerTests.[test1]';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed if schema name contains single quote]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInner''Tests'
  EXEC('CREATE PROCEDURE [MyInner''Tests].[CleanUp] AS BEGIN INSERT INTO #Actual VALUES (''[MyInner''''Tests].[CleanUp]''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInner''Tests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run '[MyInner''Tests].[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, '[MyInner''Tests].[CleanUp]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed even if name is differently cased]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[clEaNuP] AS BEGIN INSERT INTO #Actual VALUES (''[MyInnerTests].[clEaNuP]''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run '[MyInnerTests].[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, '[MyInnerTests].[clEaNuP]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes test result to be Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes an appropriate message to be written to the tSQLt.TestResult table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is an error ;) | Procedure: MyInnerTests.CleanUp | Line: 5 | Severity, State: 16, 10)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes an appropriate message to be written to the tSQLt.TestResult if there is a different error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyOtherInnerTests'
  EXEC('
    CREATE PROCEDURE [MyOtherInnerTests].[CleanUp]
    AS
    BEGIN
      /*wasting lines...*/
      RAISERROR(''This is another error ;)'',15,12);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyOtherInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyOtherInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is another error ;) | Procedure: MyOtherInnerTests.CleanUp | Line: 6 | Severity, State: 15, 12)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes an appropriate message to be written to tSQLt.TestResult even if ERROR_PROCEDURE is null]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyOtherInnerTests'
  EXEC('
    CREATE PROCEDURE [MyOtherInnerTests].[CleanUp]
    AS
    BEGIN
      /*wasting lines...*/
      EXEC(''RAISERROR(''''This is another error ;)'''',15,12)'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyOtherInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyOtherInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is another error ;) | Procedure: <NULL> | Line: 1 | Severity, State: 15, 12)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test appends message to any test error if Schema-CleanUp errors]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is a CleanUp error ;)'',15,12);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RAISERROR(''This is a Test error ;)'',16,10);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertLike @ExpectedPattern = '%This is a Test error ;)% || %This is a CleanUp error ;)%', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed even if the test errors]
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes failing test to be set to Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      EXEC tSQLt.Fail;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error causes passing test to be set to Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp error and test error still results in Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RAISERROR(''Some random error!'', 16, 10);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test appends message to any test error if Test-CleanUp errors]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[TestCleanUp]
    AS
    BEGIN
      RAISERROR(''This is a CleanUp error ;)'',15,12);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[TestCleanUp]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RAISERROR(''This is a Test error ;)'',16,10);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertLike @ExpectedPattern = '%This is a Test error ;)% || %This is a CleanUp error ;)%', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed if previous Test-CleanUp errors]
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
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp2]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserCleanUp2'');
      RAISERROR(''some error in UserCleanUp2'',16,10);
    END;
  ');
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp3]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserCleanUp3'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp1]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp2]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp3]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));


  EXEC tSQLt.Run 'MyInnerTests.[test1]', 'tSQLt.NullTestResultFormatter';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'UserCleanUp1'), (3, 'UserCleanUp2'), (4, 'UserCleanUp3');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp appends all individual error messages]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''some error in Schema-CleanUp'',16,10);
    END;
  ');
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp1]
    AS
    BEGIN
      RAISERROR(''some error in UserCleanUp1'',16,10);
    END;
  ');
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp2]
    AS
    BEGIN
      RAISERROR(''some error in UserCleanUp2'',16,10);
    END;
  ');
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp3]
    AS
    BEGIN
      RAISERROR(''some error in UserCleanUp3'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp1]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp2]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp3]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      EXEC tSQLt.Fail ''MyInnerTests.test1 has failed.'';
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', 'tSQLt.NullTestResultFormatter';
  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = '%MyInnerTests.test1%UserCleanUp1%UserCleanUp2%UserCleanUp3%Schema-CleanUp%', @Actual = @Actual;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp error causes failing test to be set to Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[TestCleanUp1]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[TestCleanUp1]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      EXEC tSQLt.Fail;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp error causes passing test to be set to Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[TestCleanUp1]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[TestCleanUp1]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp error and test error still results in Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[TestCleanUp1]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[TestCleanUp1]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RAISERROR(''test error'',16,10);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp error causes an appropriate message to be written to tSQLt.TestResult even if ERROR_PROCEDURE is null]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyOtherInnerTests'
  EXEC('
    CREATE PROCEDURE [MyOtherInnerTests].[TestCleanUp1]
    AS
    BEGIN
      /*wasting lines...*/
      EXEC(''RAISERROR(''''This is another error ;)'''',15,12)'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyOtherInnerTests].[TestCleanUp1]'')
    CREATE PROCEDURE [MyOtherInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyOtherInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is another error ;) | Procedure: <NULL> | Line: 1 | Severity, State: 15, 12)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Private-CleanUp error stops execution of all subsequent tests]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS INSERT INTO #Actual DEFAULT VALUES;
  ');
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test2] AS INSERT INTO #Actual DEFAULT VALUES;
  ');
  CREATE TABLE #Actual(Id CHAR(1) DEFAULT '*');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'RAISERROR(''Error during Private_CleanUp'',16,10);'; 
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';
  BEGIN TRY
  EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
  /*Not interested in the specific error here.*/
  END CATCH;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('*');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Private_CleanUp @Result OUTPUT gets written to tSQLt.TestResult before tSQLt stops]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @Result = ''V1234'';'; 
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_AssertNoSideEffects';

  EXEC tSQLt.Run 'MyInnerTests';

  SELECT Result INTO #Actual FROM tSQLt.TestResult
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('V1234');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed through tSQLt.Private_CleanUpCmdHandler]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp] AS BEGIN RETURN; END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUpCmdHandler';

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT _id_, CleanUpCmd INTO #Actual FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog
   WHERE(NOT EXISTS(SELECT 1 FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog WHERE CleanUpCmd LIKE '%MyInnerTests%CleanUp%'));

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual', @Message = 'Expected a call for MyInnerTests.Cleanup1';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed through tSQLt.Private_CleanUpCmdHandler]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[Test-CleanUp1] AS BEGIN RETURN; END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[Test-CleanUp2] AS BEGIN RETURN; END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[Test-CleanUp3] AS BEGIN RETURN; END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[Test-CleanUp1]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[Test-CleanUp2]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[Test-CleanUp3]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUpCmdHandler';

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT _id_, CleanUpCmd INTO #Actual FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog
   WHERE(NOT EXISTS(SELECT 1 FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog WHERE CleanUpCmd LIKE '%MyInnerTests%Test-CleanUp1%'))
      OR(NOT EXISTS(SELECT 1 FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog WHERE CleanUpCmd LIKE '%MyInnerTests%Test-CleanUp2%'))
      OR(NOT EXISTS(SELECT 1 FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog WHERE CleanUpCmd LIKE '%MyInnerTests%Test-CleanUp3%'));

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual', @Message = 'Expected a call for MyInnerTests.Test-Cleanup(s)';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Schema-CleanUp is executed in the order specified and again at the end]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUpA] AS BEGIN INSERT INTO #Actual VALUES(OBJECT_NAME(@@PROCID)); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUpB] AS BEGIN INSERT INTO #Actual VALUES(OBJECT_NAME(@@PROCID)); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp] AS BEGIN INSERT INTO #Actual VALUES(OBJECT_NAME(@@PROCID)); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUpA'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUpB'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual(OrderNumber INT IDENTITY(1,1), CleanUpName NVARCHAR(MAX) );

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1,'CleanUpA'),(2,'CleanUp'),(3,'CleanUpB'),(4,'CleanUp');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test Test-CleanUp is executed multiple times if it is specified multiple times]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[Test-CleanUp1] AS BEGIN INSERT INTO #Actual DEFAULT VALUES; END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[Test-CleanUp1]'')
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[Test-CleanUp1]'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.[Test-CleanUp1]'')
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual(WasCalled BIT DEFAULT 1);

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1),(1),(1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test any CleanUp (Test, Schema, or Private) that alters the test result adds the previous result to the error message]
AS
BEGIN
  DECLARE @TestMessage NVARCHAR(MAX) = 'BeforeMessage';

  EXEC tSQLt.Private_CleanUpCmdHandler 
         @CleanUpCmd='RAISERROR(''NewMessage'',16,10)', 
         @TestMsg = @TestMessage OUT, 
         @TestResult = 'BeforeResult' , 
         @ResultInCaseOfError = 'NewResult';
 
  EXEC tSQLt.AssertLike @ExpectedPattern = 'BeforeMessage [[]Result: BeforeResult] || %NewMessage%', @Actual = @TestMessage;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test any CleanUp adds the previous result to the error message even if the previous result is NULL]
AS
BEGIN
  DECLARE @TestMessage NVARCHAR(MAX) = 'BeforeMessage';

  EXEC tSQLt.Private_CleanUpCmdHandler 
         @CleanUpCmd='RAISERROR(''NewMessage'',16,10)', 
         @TestMsg = @TestMessage OUT, 
         @TestResult = NULL , 
         @ResultInCaseOfError = 'NewResult';
 
  EXEC tSQLt.AssertLike @ExpectedPattern = 'BeforeMessage [[]Result: <NULL>] || %NewMessage%', @Actual = @TestMessage;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test FATAL error prevents subsequent tSQLt.Run% calls]
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

  EXEC tSQLt.Run 'MyInnerTests', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an invalid state. Please reinstall tSQLt.';
  EXEC tSQLt.Run 'MyInnerTests', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test for execution in the correct place in Private_RunTest, after the outer-most test execution try catch]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO')
CREATE PROCEDURE AnnotationNoTransactionTests.[test no other objects are dropped or created if SkipTest Annotation & NoTransaction annotations are used]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO')
CREATE PROCEDURE AnnotationNoTransactionTests.[test no handler is called if SkipTest Annotation & NoTransaction annotations are used]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

/*-- TODO

Add to github
- |19|[AnnotationNoTransactionTests].[test Schema-CleanUp error causes an appropr<...>essage to be written to the tSQLt.TestResult if there is a different error]|     94|Success|
  This shouldn't happen:                                                          ^^^
- What happens when we have multiple annotations for other non-NoTransaction annotations? Did we test this???
- add 100x'=' + test status (if not PASS) followed by empty line after test-end message (if verbose)



--*/