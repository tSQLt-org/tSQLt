EXEC tSQLt.NewTestClass 'UndoTestDoublesTests';
GO
CREATE PROCEDURE UndoTestDoublesTests.[test doesn't fail if there's no test double in the database]
AS
BEGIN

  EXEC tSQLt.ExpectNoException;
  
  EXEC tSQLt.UndoTestDoubles;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a faked table]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT );

  DECLARE @OriginalObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleTable');

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';

  EXEC tSQLt.UndoTestDoubles;

  DECLARE @RestoredObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleTable');
  EXEC tSQLt.AssertEquals @Expected = @OriginalObjectId, @Actual = @RestoredObjectId;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test works with names in need of quotes]
AS
BEGIN
  EXEC('CREATE SCHEMA [A Random Schema];');
  CREATE TABLE [A Random Schema].[A Simple Table] 
  (
    Id INT
  );

  DECLARE @OriginalObjectId INT = OBJECT_ID('[A Random Schema].[A Simple Table]');

  EXEC tSQLt.FakeTable @TableName = '[A Random Schema].[A Simple Table]';

  EXEC tSQLt.UndoTestDoubles;

  DECLARE @RestoredObjectId INT = OBJECT_ID('[A Random Schema].[A Simple Table]');
  EXEC tSQLt.AssertEquals @Expected = @OriginalObjectId, @Actual = @RestoredObjectId;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores many faked tables]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable1 ( Id INT );
  CREATE TABLE UndoTestDoublesTests.aSimpleTable2 ( Id INT );
  CREATE TABLE UndoTestDoublesTests.aSimpleTable3 ( Id INT );

  SELECT X.TableName, OBJECT_ID('UndoTestDoublesTests.'+X.TableName) ObjectId
    INTO #OriginalObjectIds
    FROM (VALUES('aSimpleTable1'),('aSimpleTable2'),('aSimpleTable3')) X (TableName);

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable1';
  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable2';
  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable3';

  EXEC tSQLt.UndoTestDoubles;

  SELECT X.TableName, OBJECT_ID('UndoTestDoublesTests.'+X.TableName) ObjectId
    INTO #RestoredObjectIds
    FROM (VALUES('aSimpleTable1'),('aSimpleTable2'),('aSimpleTable3')) X (TableName);

  EXEC tSQLt.AssertEqualsTable @Expected = '#OriginalObjectIds', @Actual = '#RestoredObjectIds';

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a constraint]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT CONSTRAINT aSimpleTableConstraint CHECK(Id > 0));

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #OriginalObjectIds
    FROM (VALUES('aSimpleTableConstraint')) X (ObjectName);

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';
  EXEC tSQLt.ApplyConstraint @TableName = 'UndoTestDoublesTests.aSimpleTable', @ConstraintName = 'aSimpleTableConstraint';

  EXEC tSQLt.UndoTestDoubles;

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #RestoredObjectIds
    FROM (VALUES('aSimpleTableConstraint')) X (ObjectName);

  EXEC tSQLt.AssertEqualsTable @Expected = '#OriginalObjectIds', @Actual = '#RestoredObjectIds';

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a table that has been faked multiple times]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT );

  DECLARE @OriginalObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleTable');

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';
  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';
  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';

  EXEC tSQLt.UndoTestDoubles;

  DECLARE @RestoredObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleTable');
  EXEC tSQLt.AssertEquals @Expected = @OriginalObjectId, @Actual = @RestoredObjectId;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a trigger]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT );
  EXEC('CREATE TRIGGER aSimpleTrigger ON UndoTestDoublesTests.aSimpleTable FOR INSERT AS RETURN;');

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #OriginalObjectIds
    FROM (VALUES('aSimpleTrigger')) X (ObjectName);

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';
  EXEC tSQLt.ApplyTrigger @TableName = 'UndoTestDoublesTests.aSimpleTable', @TriggerName = 'aSimpleTrigger';

  EXEC tSQLt.UndoTestDoubles;

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #RestoredObjectIds
    FROM (VALUES('aSimpleTrigger')) X (ObjectName);

  EXEC tSQLt.AssertEqualsTable @Expected = '#OriginalObjectIds', @Actual = '#RestoredObjectIds';

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.CreateTableWithTriggersAndConstraints
  @Number NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 'CREATE TABLE UndoTestDoublesTests.aSimpleTable0 ( Id INT CONSTRAINT aSimpleTable0C1 CHECK(Id > 9) CONSTRAINT aSimpleTable0PK PRIMARY KEY);';
  SET @cmd = REPLACE(@cmd,'0',@Number);EXEC(@cmd);

  SET @cmd = 'CREATE TRIGGER aSimpleTrigger0i ON UndoTestDoublesTests.aSimpleTable0 FOR INSERT AS RETURN;';
  SET @cmd = REPLACE(@cmd,'0',@Number);EXEC(@cmd);

  SET @cmd = 'CREATE TRIGGER aSimpleTrigger0u ON UndoTestDoublesTests.aSimpleTable0 FOR UPDATE AS RETURN;';
  SET @cmd = REPLACE(@cmd,'0',@Number);EXEC(@cmd);

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints
  @Number NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = '
    EXEC tSQLt.FakeTable @TableName=''UndoTestDoublesTests.aSimpleTable0'';
    EXEC tSQLt.ApplyConstraint @TableName=''UndoTestDoublesTests.aSimpleTable0'', @ConstraintName = ''aSimpleTable0C1'';
    EXEC tSQLt.ApplyConstraint @TableName=''UndoTestDoublesTests.aSimpleTable0'', @ConstraintName = ''aSimpleTable0PK'';
    EXEC tSQLt.ApplyTrigger @TableName=''UndoTestDoublesTests.aSimpleTable0'', @TriggerName = ''aSimpleTrigger0i'';
    EXEC tSQLt.ApplyTrigger @TableName=''UndoTestDoublesTests.aSimpleTable0'', @TriggerName = ''aSimpleTrigger0u'';
  ';
  SET @cmd = REPLACE(@cmd,'0',@Number);EXEC(@cmd);

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores multiple triggers and multiple constraints on multiple tables faked multiple times]
AS
BEGIN
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '1';
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '2';
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '3';

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #OriginalObjectIds
    FROM (VALUES('aSimpleTrigger1i'),('aSimpleTrigger1u'),('aSimpleTable1C1'),('aSimpleTable1PK'),('aSimpleTable1'),
                ('aSimpleTrigger2i'),('aSimpleTrigger2u'),('aSimpleTable2C1'),('aSimpleTable2PK'),('aSimpleTable2'),
                ('aSimpleTrigger3i'),('aSimpleTrigger3u'),('aSimpleTable3C1'),('aSimpleTable3PK'),('aSimpleTable3')
    ) X (ObjectName);

  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '1';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '2';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '3';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '1';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '2';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '3';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '1';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '2';
  EXEC UndoTestDoublesTests.FakeTableAndApplyTriggersAndConstraints '3';

  EXEC tSQLt.UndoTestDoubles;

  SELECT X.ObjectName, OBJECT_ID('UndoTestDoublesTests.'+X.ObjectName) ObjectId
    INTO #RestoredObjectIds
    FROM (VALUES('aSimpleTrigger1i'),('aSimpleTrigger1u'),('aSimpleTable1C1'),('aSimpleTable1PK'),('aSimpleTable1'),
                ('aSimpleTrigger2i'),('aSimpleTrigger2u'),('aSimpleTable2C1'),('aSimpleTable2PK'),('aSimpleTable2'),
                ('aSimpleTrigger3i'),('aSimpleTrigger3u'),('aSimpleTable3C1'),('aSimpleTable3PK'),('aSimpleTable3')
    ) X (ObjectName);

  EXEC tSQLt.AssertEqualsTable @Expected = '#OriginalObjectIds', @Actual = '#RestoredObjectIds';

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test tSQLt.Private_RenamedObjectLog is empty after execution]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT );

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';

  EXEC tSQLt.UndoTestDoubles;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_RenamedObjectLog';
END;
GO

/*--
TODO
- stored procedures
- views
- functions
- rename object to unique name

--*/
