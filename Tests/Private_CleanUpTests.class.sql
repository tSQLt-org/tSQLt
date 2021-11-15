EXEC tSQLt.NewTestClass 'Private_CleanUpTests';
GO
CREATE PROCEDURE Private_CleanUpTests.[test calls tSQLt.UndoTestDoubles]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';

  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @ErrorMsg = NULL;

  SELECT _id_, Force INTO #Actual FROM tSQLt.UndoTestDoubles_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1,0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_CleanUpTests.[test calls tSQLt.Private_NoTransactionHandleTables]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.UndoTestDoubles';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';

  EXEC tSQLt.Private_CleanUp @FullTestName = NULL, @ErrorMsg = NULL;

  SELECT _id_ INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


/*-- TODO

-- CLEANUP: named cleanup x 3 (needs to execute even if there's an error during test execution)
---- there will be three clean up methods, executed in the following order
---- 1. User defined clean up for an individual test as specified in the NoTransaction annotation parameter
---- 2. User defined clean up for a test class as specified by [<TESTCLASS>].CleanUp
---- 3. tSQLt.Private_CleanUp
---- Errors thrown in any of the CleanUp methods are captured and causes the test @Result to be set to Error
---- If a previous CleanUp method errors or fails, it does not cause any following CleanUps to be skipped.
---- appropriate error messages are appended to the test msg 
---- tSQLt.Private_CleanUp Tests
----- Tables --> SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('tSQLt');
----- tSQLt.UndoTestDoubles 

--*/