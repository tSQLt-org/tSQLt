EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTableTests';
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if Action is not an acceptable value]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT);
  
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Invalid @Action parameter value.%', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Unexpected Action', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
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
/*-----------------------------------------------------------------------------------------------*/
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
/*-----------------------------------------------------------------------------------------------*/
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
/*-----------------------------------------------------------------------------------------------*/
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
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test calls tSQLt.RemoveObject if @Action is Save and @TableAction is Remove]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject';

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Remove';

  SELECT ObjectName INTO #Actual FROM tSQLt.RemoveObject_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('Private_NoTransactionHandleTableTests.Table1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
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
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if @Action is Save and @TableAction is not an acceptable value]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.SomeTable(i INT);
  
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Invalid @TableAction parameter value.%', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.SomeTable', @TableAction = 'Unacceptable';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test augments any internal error with ' tSQLt is in an unknown state: Stopping execution.']
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.SomeTable(i INT);
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute='RAISERROR(''SOME INTERNAL ERROR.'',15,11)';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an unknown state: Stopping execution. (SOME INTERNAL ERROR. | Procedure: tSQLt.RemoveObject | Line: 1)', @ExpectedSeverity = 15, @ExpectedState = 11;
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.SomeTable', @TableAction = 'Remove';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if the table does not exist]
AS
BEGIN

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Nonexistent.Table does not exist%';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'someaction', @FullTableName = 'Nonexistent.Table', @TableAction = 'sometableaction';
END;
GO
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test copies data from backup into the emptied original table if @Action is Reset and @TableAction is Restore]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  TRUNCATE TABLE Private_NoTransactionHandleTableTests.Table1;
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test deletes original table data before restoring]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  TRUNCATE TABLE Private_NoTransactionHandleTableTests.Table1;
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES(4, 'abcdef'),(6, 'dd'),(7, 'khdf');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test can restore table with identity column]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES('a'),('bb'),('cdce');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test Reset @Action with unknown @TableAction causes error]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.SomeTable(i INT);
  
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Invalid @TableAction parameter value.%', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.SomeTable', @TableAction = 'Unacceptable';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test Reset @Action with truncate @TableAction deletes all data from the table]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES('a'),('bb'),('cdce');

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Truncate';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Private_NoTransactionHandleTableTests.Table1';
END;

/*--
TODO
- Reset
-- Ignore
-- Truncate
-- Remove

--*/
