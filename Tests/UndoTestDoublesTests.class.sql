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
/*--
TODO
==> multiple constraints and triggers on a multiple tables, faked multiple times
- stored procedures
- views
- functions


Also, just review all the code.

--*/
