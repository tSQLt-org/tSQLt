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
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test calls tSQLt.RemoveObject if @Action is Save and @TableAction is Hide]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject';

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Hide';

  SELECT ObjectName INTO #Actual FROM tSQLt.RemoveObject_SpyProcedureLog;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('Private_NoTransactionHandleTableTests.Table1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not create a backup table if @Action is Save and @TableAction is Hide]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  DECLARE @OriginalObjectId INT = OBJECT_ID('Private_NoTransactionHandleTableTests.Table1');

  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables WHERE object_id <> @OriginalObjectId; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Hide';

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
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.SomeTable', @TableAction = 'Hide';
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
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test can restore table with computed column]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, computedcolumn AS UPPER(col1), col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1  VALUES(1,'a'),(2,'bb'),(3,'cdce');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';
  
  SELECT Id, col1 INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;

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
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not change the data if @Action is Reset and @TableAction Ignore]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES(1, 'a'),(2, 'bb'),(3, 'cdce');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES(4, 'jkdf'),(5, 'adfad'),(6, 'yuio');
  
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Ignore';

  SELECT TOP(0) A.* INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1 A RIGHT JOIN Private_NoTransactionHandleTableTests.Table1 X ON 1=0;

  INSERT INTO #Expected VALUES(1, 'a'),(2, 'bb'),(3, 'cdce'),(4, 'jkdf'),(5, 'adfad'),(6, 'yuio');

  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = 'Private_NoTransactionHandleTableTests.Table1';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test does not error and does not restore if @Action is Reset and @TableAction Hide]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Hide';
  
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Hide';

  SELECT * INTO #Actual FROM sys.tables WHERE object_id = OBJECT_ID('Private_NoTransactionHandleTableTests.Table1');

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Save: the second Save does nothing]
AS
BEGIN
  /* No additional temp objects are created, and any data in the backup table is unchanged (even if deleted for example) */
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = 'Private_NoTransactionHandleTableTests.Table1', @TableAction = 'Restore';

  SELECT * INTO #Actual
    FROM (
      (
        SELECT 'Extra'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
        EXCEPT
        SELECT 'Extra'[?],* FROM #Before
      )
      UNION ALL
      (
        SELECT 'Missing'[?],* FROM #Before
        EXCEPT
        SELECT 'Missing'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
      )
    ) X;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Save: the second Save does nothing to the existing backup table]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  DECLARE @OriginalBackupTableName NVARCHAR(MAX) = (SELECT BackupName FROM #TableBackupLog WHERE OriginalName = '[Private_NoTransactionHandleTableTests].[Table1]');
  EXEC('DELETE FROM '+@OriginalBackupTableName+';');

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  
  
  EXEC tSQLt.AssertEmptyTable @TableName = @OriginalBackupTableName;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[Eclipse #TableBackupLog and execute Save & Reset]
AS
BEGIN
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Save(Eclipsed), Reset(Eclipsed), Reset: gets back to point A]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  /*Point A*/
  SELECT * INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1;
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC Private_NoTransactionHandleTableTests.[Eclipse #TableBackupLog and execute Save & Reset];
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  
  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Save, Reset, Reset: gets back to point A]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  /*Point A*/
  SELECT * INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1;
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  
  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[Eclipse #TableBackupLog and execute Save]
AS
BEGIN
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
END;
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Save(Eclipsed), Reset: gets back to point A]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  /*Point A*/
  SELECT * INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1;
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC Private_NoTransactionHandleTableTests.[Eclipse #TableBackupLog and execute Save];
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  
  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Reset, Reset: gets back to point A]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');
  /*Point A*/
  SELECT * INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1;
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  
  SELECT * INTO #Actual FROM Private_NoTransactionHandleTableTests.Table1;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Restore, @Action Save, Reset: removes entry from #TableBackupLog]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));
  INSERT INTO #TableBackupLog VALUES ('SomeUnrelatedTable','tSQLt_SomeUnrelatedTable_Temp');

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Restore';

  SELECT TOP(0) A.* INTO #Expected FROM #TableBackupLog A RIGHT JOIN #TableBackupLog X ON 1=0;

  INSERT INTO #Expected VALUES ('SomeUnrelatedTable','tSQLt_SomeUnrelatedTable_Temp');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#TableBackupLog';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Hide, @Action Save, and table has be previously hidden, do nothing]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');

  EXEC tSQLt.RemoveObject @ObjectName = '[Private_NoTransactionHandleTableTests].[Table1]'; /* Hide here */
  SELECT object_id, SCHEMA_NAME(schema_id) [schema_name], name INTO #Before FROM sys.tables; 

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Hide';

  SELECT * INTO #Actual
    FROM (
      (
        SELECT 'Extra'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
        EXCEPT
        SELECT 'Extra'[?],* FROM #Before
      )
      UNION ALL
      (
        SELECT 'Missing'[?],* FROM #Before
        EXCEPT
        SELECT 'Missing'[?],object_id, SCHEMA_NAME(schema_id) [schema_name], name FROM sys.tables
      )
    ) X;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Truncate, @Action Save, Save, Reset, Save, Reset, Reset: table is empty]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (4,'e');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (5,'d');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (6,'f');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (7,'t');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (8,'g');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Truncate';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Private_NoTransactionHandleTableTests.Table1';  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test if @TableAction is Ignore, @Action Save, Save, Reset, Reset: table is unaltered]
AS
BEGIN
  CREATE TABLE Private_NoTransactionHandleTableTests.Table1 (Id INT, col1 NVARCHAR(MAX));
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (2,'c'), (3,'a');

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Ignore';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (4,'e');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Save', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Ignore';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (6,'f');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Ignore';
  INSERT INTO Private_NoTransactionHandleTableTests.Table1 VALUES (7,'t');
  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Reset', @FullTableName = '[Private_NoTransactionHandleTableTests].[Table1]', @TableAction = 'Ignore';

  SELECT TOP(0) A.* INTO #Expected FROM Private_NoTransactionHandleTableTests.Table1 A RIGHT JOIN Private_NoTransactionHandleTableTests.Table1 X ON 1=0;
  
  INSERT INTO #Expected VALUES (2,'c'), (3,'a'), (4,'e'), (6,'f'), (7,'t');

  EXEC tSQLt.AssertEqualsTable @Expected ='#Expected', @Actual = 'Private_NoTransactionHandleTableTests.Table1';  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO


CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test TODO]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
--tSQLt.Run 'Private_NoTransactionHandleTableTests'.[test if @TableAction is Restore, @Action Save, Save: the second Save does nothing]'
/*--
TODO

I can rerun them and nothing "bad" happens. But what is "bad"?
What about when I intersperse calls to Save/Reset with UndoTestDoubles?

Some scenarios to consider
1: Save, Reset
2: Save, Save, Reset
3: Save, Reset, Reset
4: Save, Save, Reset, Reset

@TableAction = Restore
5: ?*test* Save (Restore), Save (Restore) --> The second save does nothing, because it checks the #TableBackupLog.
6: Save (Restore), Save (Restore) Eclipsed #TableBackupLog --> The second save takes a new backup because it cannot see #TableBackupLog.
7: ?*test* Save (Restore), Save (Restore) Eclipsed #TableBackupLog, Reset (Restore) Eclipsed #TableBackupLog, Reset (Restore) --> Should be equivalent to scenario 1.
8: ?*test* Save (Restore), Save (Restore), Reset (Restore), Reset (Restore) --> Should be equivalent to scenario 1.
9: ?*test* Save (Restore), Save (Restore) Eclipsed #TableBackupLog, Reset (Restore) --> Should be equivalent to scenario 1.
17: ?*test* Save (Restore), Reset (Restore), Reset (Restore) --> Should be equivalent to scenario 1.

@TableAction = Hide
10: ?*test* Save (Hide), Save (Hide) --> We can't hide something we can't see. Check to see if the object is already hidden, if so do nothing. If not, throw an error.
11: Save (Hide), Save (Hide) Eclipsed #TableBackupLog --> Same as scenario 10.
12: Save (Hide), Save (Hide) Eclipsed #TableBackupLog, Reset (Hide) Eclipsed #TableBackupLog, Reset (Hide) --> Should be equivalent to Scenario 1.
13: Save (Hide), Save (Hide), Reset (Hide), Reset (Hide) -->  Should be equivalent to Scenario 1.
14: Save (Hide), Save (Hide) Eclipsed #TableBackupLog, Reset (Hide) -->  Should be equivalent to Scenario 1.
18: Save (Hide), Reset (Hide), Reset (Hide) --> Should be equivalent to scenario 1.

@TableAction = Truncate
15: ?*test* Save (Truncate), Save (Truncate), Reset (Truncate), Save (Truncate), Reset (Truncate), Reset (Truncate) -->  Should be idempotent. Any table with TableAction=Truncate should be empty after any number of save, reset actions.

@TableAction = Ignore
16: ?*test* Save (Ignore), Save (Ignore), Reset (Ignore), Reset (Ignore) --> No Op. ExpectNoException.s

--*/
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO