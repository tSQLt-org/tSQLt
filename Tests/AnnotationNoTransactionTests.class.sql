EXEC tSQLt.NewTestClass 'AnnotationNoTransactionTests';
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test runs test without transaction]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
--[@tSQLt:SkipTest]('TODO: needs other tests first')
CREATE PROCEDURE AnnotationNoTransactionTests.[test produces meaningful error when pre and post transactions counts don't match]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS BEGIN TRAN;
  ');

  --EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test transaction name is NULL in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test succeeding test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test failing test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
CREATE PROCEDURE AnnotationNoTransactionTests.[test recoverable erroring test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
--[@tSQLt:NoTransaction]()
--[@tSQLt:SkipTest]('TODO: needs other tests first')
CREATE PROCEDURE AnnotationNoTransactionTests.[test an unrecoverable erroring test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test should cause unrecoverable error] AS SELECT CAST(''Some obscure string'' AS INT);
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test should cause unrecoverable error]';
  SELECT Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Error','Conversion failed when converting the varchar value ''Some obscure string'' to data type int.[16,1]{MyInnerTests.test should cause unrecoverable error,3}');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls tSQLt.Private_CleanUp]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;
  ');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT FullTestName INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('[MyInnerTests].[test1]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is appended to tSQLt.TestResult.Msg]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test1] AS PRINT 1/0;
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is called before the test result message is printed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
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
/*-- TODO

-- CLEANUP: named cleanup x 3 (needs to execute even if there's an error during test execution)
---- there will be three clean up methods, executed in the following order
---- 1. User defined clean up for an individual test as specified in the NoTransaction annotation parameter
---- 2. User defined clean up for a test class as specified by [<TESTCLASS>].CleanUp
---- 3. tSQLt.Private_CleanUp
---- test for execution in the correct place in Private_RunTest
---- test errors in any are captured and cause the test to Error
---- If a previous CleanUp method errors or fails, it does not cause any following CleanUps to be skipped.
---- appropriate error messages are appended to the test msg 
---- tSQLt.Private_CleanUp Tests
----- Tables --> SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('tSQLt');
----- tSQLt.UndoTestDoubles 

-- transaction opened during test
-- transaction commited during test
-- test skipped?
-- inner-transaction-free test errors
-- confirm pre and post transaction counts match
-- [test produces meaningful error when pre and post transactions counts don't match]
--  we still need to save the TranName as something somewhere.
-- settings need to be preserved (e.g. SummaryError)
-- Ctrl+9 is broken with NoTransaction
-- preserve content of all tSQLt.% tables

--*/