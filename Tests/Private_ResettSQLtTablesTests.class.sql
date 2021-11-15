EXEC tSQLt.NewTestClass 'Private_ResettSQLtTablesTests';
GO
CREATE PROCEDURE Private_ResettSQLtTablesTests.[test does not call tSQLt.Private_ResettSQLtTable if tSQLt.Private_ResettSQLtTableAction is empty]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResettSQLtTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_ResettSQLtTableAction';

  EXEC tSQLt.Private_ResettSQLtTables;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_ResettSQLtTable_SpyProcedureLog';

END;
GO
CREATE PROCEDURE Private_ResettSQLtTablesTests.[test calls tSQLt.Private_ResettSQLtTable if tSQLt.Private_ResettSQLtTableAction contains a table]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResettSQLtTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_ResettSQLtTableAction';
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl1'',''Restore'');')

  EXEC tSQLt.Private_ResettSQLtTables;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_ResettSQLtTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ResettSQLtTablesTests.[test calls tSQLt.Private_ResettSQLtTable for each table in tSQLt.Private_ResettSQLtTableAction]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResettSQLtTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_ResettSQLtTableAction';
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl2'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl3'',''Restore'');')

  EXEC tSQLt.Private_ResettSQLtTables;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_ResettSQLtTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1'),('tbl2'),('tbl3');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ResettSQLtTablesTests.[test calls tSQLt.Private_ResettSQLtTable only for 'Restore' tables]
AS
BEGIN
  --EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SavetSQLtTable';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResettSQLtTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_ResettSQLtTableAction';
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl2'',''Ignore'');')
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl3'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_ResettSQLtTableAction VALUES(''tbl4'',''Other'');')

  EXEC tSQLt.Private_ResettSQLtTables @save=0;

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_ResettSQLtTable_SpyProcedureLog;

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