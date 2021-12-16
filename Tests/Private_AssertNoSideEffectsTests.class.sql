EXEC tSQLt.NewTestClass 'Private_AssertNoSideEffectsTests';
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE FUNCTION Private_AssertNoSideEffectsTests.[Faked_GenerateCommand](
  @BeforeExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @AfterExecutionObjectSnapshotTableName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT @BeforeExecutionObjectSnapshotTableName + '<><><>' + @AfterExecutionObjectSnapshotTableName Command;
GO
CREATE PROCEDURE Private_AssertNoSideEffectsTests.[test Private_AssertNoSideEffects is using Private_CleanUpCmdHandler]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_AssertNoSideEffects_GenerateCommand', @FakeFunctionName = 'Private_AssertNoSideEffectsTests.[Faked_GenerateCommand]';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUpCmdHandler';

  EXEC tSQLt.Private_AssertNoSideEffects @BeforeExecutionObjectSnapshotTableName = 'BeforeTable', @AfterExecutionObjectSnapshotTableName = 'AfterTable', @TestResult = 'Result1', @TestMsg = 'Message1';

  SELECT CleanUpCmd, TestResult, TestMsg INTO #Actual FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES ('BeforeTable<><><>AfterTable','Result1','Message1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_AssertNoSideEffectsTests.[test Private_AssertNoSideEffects is using Private_CleanUpCmdHandler with @TestResult and @TestMsg as OUTPUT parameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUpCmdHandler', @CommandToExecute = 'SET @TestResult = ''Altered Test Result'';SET @TestMsg = ''Altered Test Message'';';

  DECLARE @TestResult NVARCHAR(MAX) = 'Result1';
  DECLARE @TestMessage NVARCHAR(MAX) = 'Message1';

  EXEC tSQLt.Private_AssertNoSideEffects @BeforeExecutionObjectSnapshotTableName = 'BeforeTable', @AfterExecutionObjectSnapshotTableName = 'AfterTable', @TestResult = @TestResult OUT, @TestMsg = @TestMessage OUT;

  SELECT @TestResult TestResult, @TestMessage TestMsg INTO #Actual

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES ('Altered Test Result','Altered Test Message');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
