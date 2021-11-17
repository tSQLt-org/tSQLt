EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTableTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if Action is not an acceptable value]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid @Action parameter value. tSQLt is in an unknown state: Stopping execution.', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Unexpected Action', @FullTableName = '[someschema].[sometable]', @TableAction = 'Restore';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test creates new table and saves its name in #TableBackupLog if Action is Save]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));

  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  DECLARE @BackupName NVARCHAR(MAX) = (SELECT BackupName FROM #TableBackupLog WHERE OriginalName = 'Private_NoTransactionHandleTableTests.Table1');

  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'Private_NoTransactionHandleTableTests.Table1', @Actual = @BackupName;
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test calls tSQLt.Private_MarktSQLtTempObject on new object]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  DECLARE @BackupName NVARCHAR(MAX) = (SELECT BackupName FROM #TableBackupLog WHERE OriginalName = 'Private_NoTransactionHandleTableTests.Table1');

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES(ISNULL(@BackupName,'Backup table not found.'), N'TABLE', NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not create a backup table if @Action is Save and the @TableAction is Truncate]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));

  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Truncate';

  SELECT * INTO #Actual
    FROM (
      (
        SELECT 'Extra'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
        EXCEPT
        SELECT 'Extra'[?],* FROM #BEFORE
      )
      UNION ALL
      (
        SELECT 'Missing'[?],* FROM #BEFORE
        EXCEPT
        SELECT 'Missing'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
      )
    ) X;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not create a backup table if @Action is Save and the @TableAction is Ignore]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));

  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Ignore';

  SELECT * INTO #Actual
    FROM (
      (
        SELECT 'Extra'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
        EXCEPT
        SELECT 'Extra'[?],* FROM #BEFORE
      )
      UNION ALL
      (
        SELECT 'Missing'[?],* FROM #BEFORE
        EXCEPT
        SELECT 'Missing'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
      )
    ) X;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test calls tSQLt.RemoveObject if @Action is Save and @TableAction is Remove]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject';

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Some.Table', @TableAction = 'Remove';

  SELECT ObjectName INTO #Actual FROM tSQLt.RemoveObject_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('Some.Table');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not create a backup table if @Action is Save and @TableAction is Remove]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  DECLARE @OriginalObjectId INT = OBJECT_ID('Private_NoTransactionHandleTableTests.Table1');

  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables WHERE object_id <> @OriginalObjectId; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Remove';

  SELECT * INTO #Actual
    FROM (
      (
        SELECT 'Extra'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables WHERE object_id <> @OriginalObjectId
        EXCEPT
        SELECT 'Extra'[?],* FROM #BEFORE
      )
      UNION ALL
      (
        SELECT 'Missing'[?],* FROM #BEFORE
        EXCEPT
        SELECT 'Missing'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables WHERE object_id <> @OriginalObjectId
      )
    ) X;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if @Action is Save and @TableAction is not an acceptable value]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid @TableAction parameter value. tSQLt is in an unknown state: Stopping execution.', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[someschema].[sometable]', @TableAction = 'Unacceptable';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test augments any internal error with ' tSQLt is in an unknown state: Stopping execution.']
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute='RAISERROR(''SOME INTERNAL ERROR.'',16,10)';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'SOME INTERNAL ERROR. tSQLt is in an unknown state: Stopping execution.', @ExpectedSeverity = NULL, @ExpectedState = NULL;
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Some.Table', @TableAction = 'Remove';
END;
GO

/*--
TODO

- If TableAction is not Restore, throw an error.
- If FullTableName is not found, throw an error?
- Save
-- TableAction = Restore
--- Saves an exact copy of the table data into a tSQLt Temp Object table
--- tSQLt Temp Object is marked as IsTempObject = 1
-- All errors are augmented with "tSQLt is in an unknown state: Stopping execution."
- Reset
-- TableAction = Restore
--- Restores --> truncates original table and uses tSQLt Temp Object table to insert/restore data 

--*/
