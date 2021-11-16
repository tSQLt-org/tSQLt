EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTableTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if Action is not an acceptable value]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid Action. @Action parameter must be one of the following: Save, Reset.', @ExpectedSeverity = 16, @ExpectedState = 10;

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



/*--
TODO

- If TableAction is not Restore, throw an error.
- If FullTableName is not found, throw an error?
- Save
-- TableAction = Restore
--- Saves an exact copy of the table data into a tSQLt Temp Object table
--- tSQLt Temp Object is marked as IsTempObject = 1
- Reset
-- TableAction = Restore
--- Restores --> truncates original table and uses tSQLt Temp Object table to insert/restore data 

--*/