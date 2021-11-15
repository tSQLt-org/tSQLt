EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTablesTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test does not call tSQLt.Private_NoTransactionHandleTable if tSQLt.Private_NoTransactionTableAction is empty]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';

  EXEC tSQLt.Private_NoTransactionHandleTables;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog';

END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test calls tSQLt.Private_NoTransactionHandleTable if tSQLt.Private_NoTransactionTableAction contains a table]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')

  EXEC tSQLt.Private_NoTransactionHandleTables;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test calls tSQLt.Private_NoTransactionHandleTable for each table in tSQLt.Private_NoTransactionTableAction]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl2'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl3'',''Restore'');')

  EXEC tSQLt.Private_NoTransactionHandleTables;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1'),('tbl2'),('tbl3');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test calls tSQLt.Private_NoTransactionHandleTable only for 'Restore' tables]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl2'',''Ignore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl3'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl4'',''Other'');')

  EXEC tSQLt.Private_NoTransactionHandleTables @save=0;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1'),('tbl3');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO




/*--
TODO

- Tables --> SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('tSQLt');
Action   - Table Name
Restore  - Private_NewTestClassList
Restore  - Run_LastExecution
Restore  - Private_Configurations
Ignore   - CaptureOutputLog
Ignore   - Private_RenamedObjectLog
Ignore   - TestResult

--*/