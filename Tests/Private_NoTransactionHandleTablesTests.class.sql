EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTablesTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test does not call tSQLt.Private_NoTransactionHandleTable if tSQLt.Private_NoTransactionTableAction is empty]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog';

END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test calls tSQLt.Private_NoTransactionHandleTable if tSQLt.Private_NoTransactionTableAction contains a table]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

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
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl2'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl3'',''Restore'');')

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1'),('tbl2'),('tbl3');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test does not call tSQLt.Private_NoTransactionHandleTable for 'Ignore' tables]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl2'',''Ignore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl3'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl4'',''Other'');')

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

  SELECT FullTableName INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1'),('tbl3'),('tbl4');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test passes @Action to tSQLt.Private_NoTransactionHandleTable for each table]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTable';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NoTransactionTableAction';
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl1'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl2'',''Restore'');')
  EXEC('INSERT INTO tSQLt.Private_NoTransactionTableAction VALUES(''tbl3'',''Restore'');')

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='A Specific Action';

  SELECT FullTableName, Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTable_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tbl1', 'A Specific Action'),('tbl2', 'A Specific Action'),('tbl3', 'A Specific Action');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTablesTests.[test is rerunnable]
AS
BEGIN

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Save';
  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Restore';
  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Restore';

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #RestoredObjectIds
    FROM sys.objects O;

  SELECT * INTO #ShouldBeEmpty
  FROM
  (
    SELECT 'Expected' T,* FROM (SELECT * FROM #OriginalObjectIds EXCEPT SELECT * FROM #RestoredObjectIds) E
    UNION ALL
    SELECT 'Actual' T,* FROM (SELECT * FROM #RestoredObjectIds EXCEPT SELECT * FROM #OriginalObjectIds) A
  ) T;
  EXEC tSQLt.AssertEmptyTable @TableName = '#ShouldBeEmpty';
END;
GO
