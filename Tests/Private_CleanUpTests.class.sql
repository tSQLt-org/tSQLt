EXEC tSQLt.NewTestClass 'Private_CleanUpTests';
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test calls tSQLt.UndoTestDoubles with @Force=0]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';

  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = NULL, @ErrorMsg = NULL;

  SELECT _id_, Force INTO #Actual FROM tSQLt.UndoTestDoubles_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1,0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test calls tSQLt.Private_NoTransactionHandleTables with @Action='Reset']
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';

  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = NULL, @ErrorMsg = NULL;

  SELECT _id_, Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1, 'Reset');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test calls tSQLt.Private_CleanUpCmdHandler for only UndoTestDoubles and HandleTables in the correct order]
AS
BEGIN

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUpCmdHandler';

  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = NULL, @ErrorMsg = NULL;

  SELECT _id_, CleanUpCmd INTO #Actual FROM tSQLt.Private_CleanUpCmdHandler_SpyProcedureLog;
  SELECT TOP(0) A._id_, A.CleanUpCmd AS [%CleanUpCmd] INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1,'%tSQLt.Private_NoTransactionHandleTables%'),(2,'%tSQLt.UndoTestDoubles%');

  SELECT * INTO #Compare
    FROM(
      SELECT '>' _R_,* FROM #Actual AS A WHERE NOT EXISTS(SELECT 1 FROM #Expected E WHERE A._id_ = E._id_ AND A.CleanUpCmd LIKE E.[%CleanUpCmd])
       UNION ALL
      SELECT '<' _R_,* FROM #Expected AS E WHERE NOT EXISTS(SELECT 1 FROM #Actual A WHERE A._id_ = E._id_ AND A.CleanUpCmd LIKE E.[%CleanUpCmd])
    )X
  EXEC tSQLt.AssertEmptyTable @TableName = '#Compare';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test UndoTestDoubles error message is appended to @ErrorMsg]
AS
BEGIN

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles', @CommandToExecute = 'RAISERROR(''some cleanup error'',16, 10)';

  DECLARE @ErrorMsg NVARCHAR(MAX) = 'previous error';
  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = NULL, @ErrorMsg = @ErrorMsg OUT;

  EXEC tSQLt.AssertLike @ExpectedPattern = 'previous error%some cleanup error%', @Actual = @ErrorMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test UndoTestDoubles error causes @Result to be set to Error]
AS
BEGIN

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles', @CommandToExecute = 'RAISERROR(''some cleanup error'',16, 10)';

  DECLARE @Result NVARCHAR(MAX) = 'NOT ERROR';
  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = @Result OUT, @ErrorMsg = NULL;

  EXEC tSQLt.AssertEqualsString @Expected = 'Error', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test HandleTables error is appended to @ErrorMsg]
AS
BEGIN

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables', @CommandToExecute = 'RAISERROR(''some cleanup error'',16, 10)';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';

  DECLARE @ErrorMsg NVARCHAR(MAX) = 'previous error';
  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = NULL, @ErrorMsg = @ErrorMsg OUT;

  EXEC tSQLt.AssertLike @ExpectedPattern = 'previous error%some cleanup error%', @Actual = @ErrorMsg;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpTests.[test HandleTables error causes @Result to be set to FATAL]
AS
BEGIN

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables', @CommandToExecute = 'RAISERROR(''some cleanup error'',16, 10)';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';

  DECLARE @Result NVARCHAR(MAX) = 'NOT ERROR';
  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @Result = @Result OUT, @ErrorMsg = NULL;

  EXEC tSQLt.AssertEqualsString @Expected = 'FATAL', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
