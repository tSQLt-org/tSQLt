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
CREATE PROCEDURE UndoTestDoublesTests.[test restores objects after multiple fake actions and deletes test doubles]
AS
BEGIN
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '1';
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '2';
  EXEC UndoTestDoublesTests.CreateTableWithTriggersAndConstraints '3';

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name 
    INTO #OriginalObjectIds
    FROM sys.objects O;

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

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name 
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
CREATE PROCEDURE UndoTestDoublesTests.[test tSQLt.Private_RenamedObjectLog is empty after execution]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.aSimpleTable ( Id INT );

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleTable';

  EXEC tSQLt.UndoTestDoubles;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_RenamedObjectLog';
END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a faked stored procedure]
AS
BEGIN
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleSSP @Id INT AS RETURN;');
  DECLARE @OriginalObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleSSP');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'UndoTestDoublesTests.aSimpleSSP';

  EXEC tSQLt.UndoTestDoubles;

  DECLARE @RestoredObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleSSP');
  EXEC tSQLt.AssertEquals @Expected = @OriginalObjectId, @Actual = @RestoredObjectId;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a faked view]
AS
BEGIN
  EXEC ('CREATE VIEW UndoTestDoublesTests.aSimpleView AS SELECT NULL X;');
  DECLARE @OriginalObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleView');
  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleView';

  EXEC tSQLt.UndoTestDoubles;

  DECLARE @RestoredObjectId INT = OBJECT_ID('UndoTestDoublesTests.aSimpleView');
  EXEC tSQLt.AssertEquals @Expected = @OriginalObjectId, @Actual = @RestoredObjectId;

END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test restores a faked function]
AS
BEGIN
  EXEC ('CREATE FUNCTION UndoTestDoublesTests.aSimpleITVF() RETURNS TABLE AS RETURN SELECT NULL X;');
  EXEC ('CREATE FUNCTION UndoTestDoublesTests.aSimpleTVF() RETURNS @R TABLE(i INT) AS BEGIN RETURN; END;');
  EXEC ('CREATE FUNCTION UndoTestDoublesTests.aSimpleSVF() RETURNS INT AS BEGIN RETURN NULL; END;');
  EXEC ('CREATE FUNCTION UndoTestDoublesTests.aTempSVF() RETURNS INT AS BEGIN RETURN NULL; END;');
  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.FakeFunction @FunctionName = 'UndoTestDoublesTests.aSimpleITVF', @FakeDataSource = '(VALUES(NULL))X(X)';
  EXEC tSQLt.FakeFunction @FunctionName = 'UndoTestDoublesTests.aSimpleTVF', @FakeDataSource = '(VALUES(NULL))X(X)';
  EXEC tSQLt.FakeFunction @FunctionName = 'UndoTestDoublesTests.aSimpleSVF', @FakeFunctionName = 'UndoTestDoublesTests.aTempSVF';


  EXEC tSQLt.UndoTestDoubles;

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
CREATE PROCEDURE UndoTestDoublesTests.[test objects renamed by RemoveObject are restored if there is no other object of the same original name]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';

  EXEC tSQLt.UndoTestDoubles;

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
CREATE PROCEDURE UndoTestDoublesTests.[test objects renamed by RemoveObject are restored and conflicting objects with IsTempObject property are deleted]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Who came up with that name?'';');
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.aSimpleTable', @ObjectType = N'PROCEDURE', @NewNameOfOriginalObject = '';
  EXEC tSQLt.UndoTestDoubles;

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
CREATE PROCEDURE UndoTestDoublesTests.[test synonyms are restored]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');
  EXEC ('CREATE SYNONYM UndoTestDoublesTests.aSimpleSynonym FOR UndoTestDoublesTests.aSimpleTable;');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.aSimpleSynonym';

  EXEC tSQLt.UndoTestDoubles;

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
CREATE PROCEDURE UndoTestDoublesTests.[test doubled synonyms with IsTempObject property are deleted]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');
  EXEC ('CREATE VIEW UndoTestDoublesTests.aSimpleObject AS SELECT 1 X;');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleObject';
  EXEC ('CREATE SYNONYM UndoTestDoublesTests.aSimpleObject FOR UndoTestDoublesTests.aSimpleTable;');
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName='UndoTestDoublesTests.aSimpleObject', @ObjectType='SYNONYM', @NewNameOfOriginalObject = '';
  
  EXEC tSQLt.UndoTestDoubles;

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
CREATE PROCEDURE UndoTestDoublesTests.[test drops only objects that are marked as temporary (IsTempObject = 1)]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);

  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Attempting to remove object(s) that is/are not marked as temporary. Use @Force = 1 to override. ([UndoTestDoublesTests].[SimpleTable1])', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test does not drop multiple unmarked objects (IsTempObject is not set or is not 1)]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);

  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2';
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable3';

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Attempting to remove object(s) that is/are not marked as temporary. Use @Force = 1 to override. ([UndoTestDoublesTests].[SimpleTable1], [UndoTestDoublesTests].[SimpleTable2], [UndoTestDoublesTests].[SimpleTable3])', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test does not drop marked object where IsTempObject is not 1]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);

  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC sys.sp_addextendedproperty 
       @name = N'tSQLt.IsTempObject',
       @value = 42, 
       @level0type = N'SCHEMA', @level0name = 'UndoTestDoublesTests', 
       @level1type = N'TABLE',  @level1name = 'SimpleTable1';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Attempting to remove object(s) that is/are not marked as temporary. Use @Force = 1 to override. ([UndoTestDoublesTests].[SimpleTable1])', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
CREATE PROCEDURE UndoTestDoublesTests.[test objects renamed by RemoveObject are restored and conflicting objects without IsTempObject property are deleted if @Force=1]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Who came up with that name?'';');

  EXEC tSQLt.UndoTestDoubles @Force=1;

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
CREATE PROCEDURE UndoTestDoublesTests.[test warning message is printed for objects without IsTempObject property that are deleted if @Force=1]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Who came up with that name?'';');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC sys.sp_dropextendedproperty 
   @name = N'tSQLt.IsTempObject',
   @level0type = N'SCHEMA', @level0name = 'tSQLt', 
   @level1type = N'TABLE',  @level1name = 'Private_Print_SpyProcedureLog';   

  EXEC tSQLt.UndoTestDoubles @Force=1;
  
  SELECT Message INTO #Actual FROM tSQLt.Private_Print_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('WARNING: @Force has been set to 1. Overriding the following error(s):Attempting to remove object(s) that is/are not marked as temporary. Use @Force = 1 to override. ([UndoTestDoublesTests].[aSimpleTable])');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/* --------------------------------------------------------------------------------------------- */
GO
CREATE PROCEDURE UndoTestDoublesTests.[test objects that are replaced multiple times by objects not marked as IsTempObject are restored if @Force=1]
AS
BEGIN
  EXEC ('CREATE TABLE UndoTestDoublesTests.aSimpleTable(i INT);');

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Replacement 1'';');
  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Replacement 2'';');
  EXEC tSQLt.RemoveObject @ObjectName='UndoTestDoublesTests.aSimpleTable';
  EXEC ('CREATE PROCEDURE UndoTestDoublesTests.aSimpleTable AS PRINT ''Replacement 3'';');

  EXEC tSQLt.UndoTestDoubles @Force=1;

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
/* --------------------------------------------------------------------------------------------- */
GO
CREATE PROCEDURE UndoTestDoublesTests.[test non-testdouble object with @IsTempObjects=1 is also dropped]
AS
BEGIN
  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
  INTO #OriginalObjectIds
  FROM sys.objects O;

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1', @ObjectType=N'TABLE', @NewNameOfOriginalObject=NULL;
  
  EXEC tSQLt.UndoTestDoubles;

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
/* --------------------------------------------------------------------------------------------- */
GO
CREATE PROCEDURE UndoTestDoublesTests.[test multiple non-testdouble objects with @IsTempObjects=1 are all dropped]
AS
BEGIN
  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);

  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable3', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;

  EXEC tSQLt.UndoTestDoubles;

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
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test recovers table that was first faked and then removed]
AS
BEGIN
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);

  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.FakeTable @TableName = 'UndoTestDoublesTests.SimpleTable1';
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';

  EXEC tSQLt.UndoTestDoubles;

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
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test throws useful error if two objects with @IsTempObject<>1 need to be renamed to the same name]
AS
BEGIN

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Attempting to rename two or more objects to the same name. Use @Force = 1 to override, only first object of each rename survives. ({[[]tSQLt_tempobject_%], [[]tSQLt_tempobject_%]}-->[[]UndoTestDoublesTests].[[]SimpleTable1])', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test throws useful error if there are multiple object tuples with @IsTempObject<>1 needing to be renamed to the same name]
AS
BEGIN

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2';
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2';
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2';
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable3';
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable3';

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Attempting to rename two or more objects to the same name. Use @Force = 1 to override, only first object of each rename survives. ({[[]tSQLt_tempobject_%], [[]tSQLt_tempobject_%]}-->[[]UndoTestDoublesTests].[[]SimpleTable1]; {[[]tSQLt_tempobject_%], [[]tSQLt_tempobject_%], [[]tSQLt_tempobject_%]}-->[[]UndoTestDoublesTests].[[]SimpleTable2]; {[[]tSQLt_tempobject_%], [[]tSQLt_tempobject_%]}-->[[]UndoTestDoublesTests].[[]SimpleTable3])', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test if two objects with @IsTempObject<>1 need to be renamed to the same name and @Force=1 the oldest survives]
AS
BEGIN

  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  INSERT INTO UndoTestDoublesTests.SimpleTable1 VALUES (6);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  INSERT INTO UndoTestDoublesTests.SimpleTable1 VALUES (4);
  EXEC tSQLt.RemoveObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1';

  EXEC tSQLt.UndoTestDoubles @Force=1;
  
  SELECT i INTO #Actual FROM UndoTestDoublesTests.SimpleTable1;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(6);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test two objects with @IsTempObject<>1 and the same name but in different schemas are restored]
AS
BEGIN
  EXEC('CREATE SCHEMA RandomSchema1;');
  CREATE TABLE RandomSchema1.SimpleTable1 (i INT);
  INSERT INTO RandomSchema1.SimpleTable1 VALUES (4);
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable1';

  EXEC('CREATE SCHEMA RandomSchema2;');
  CREATE TABLE RandomSchema2.SimpleTable1 (i INT);
  INSERT INTO RandomSchema2.SimpleTable1 VALUES (6);
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema2.SimpleTable1';

  EXEC tSQLt.UndoTestDoubles;
  
  SELECT * INTO #Actual
    FROM(
      SELECT 'RandomSchema1' [schema_name], i FROM RandomSchema1.SimpleTable1
      UNION
      SELECT 'RandomSchema2' [schema_name], i FROM RandomSchema2.SimpleTable1
    ) A

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('RandomSchema1', 4),('RandomSchema2',6);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test throws useful error if there are multiple object tuples in separate schemata but all with the same name]
AS
BEGIN

  EXEC('CREATE SCHEMA RandomSchema1;');
  EXEC('CREATE SCHEMA RandomSchema2;');

  DECLARE @CurrentTableObjectId INT
  CREATE TABLE RandomSchema1.SimpleTable1 (i INT);
  SET @CurrentTableObjectId = OBJECT_ID('RandomSchema1.SimpleTable1');
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable1';
  DECLARE @Name1A NVARCHAR(MAX) = OBJECT_NAME(@CurrentTableObjectId);

  CREATE TABLE RandomSchema1.SimpleTable1 (i INT);
  SET @CurrentTableObjectId = OBJECT_ID('RandomSchema1.SimpleTable1');
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable1';
  DECLARE @Name1B NVARCHAR(MAX) = OBJECT_NAME(@CurrentTableObjectId);

  CREATE TABLE RandomSchema2.SimpleTable1 (i INT);
  SET @CurrentTableObjectId = OBJECT_ID('RandomSchema2.SimpleTable1');
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema2.SimpleTable1';
  DECLARE @Name2A NVARCHAR(MAX) = OBJECT_NAME(@CurrentTableObjectId);

  CREATE TABLE RandomSchema2.SimpleTable1 (i INT);
  SET @CurrentTableObjectId = OBJECT_ID('RandomSchema2.SimpleTable1');
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema2.SimpleTable1';
  DECLARE @Name2B NVARCHAR(MAX) = OBJECT_NAME(@CurrentTableObjectId);

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 'Attempting to rename two or more objects to the same name. Use @Force = 1 to override, only first object of each rename survives. ({['+@Name1A+'], ['+@Name1B+']}-->[RandomSchema1].[SimpleTable1]; {['+@Name2A+'], ['+@Name2B+']}-->[RandomSchema2].[SimpleTable1])'
  EXEC tSQLt.ExpectException @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.UndoTestDoubles;
END;
GO
/** ------------------------------------------------------------------------------------------- **/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test can handle the kitchen sink]
AS
BEGIN
  EXEC('CREATE SCHEMA RandomSchema1;');
  EXEC('CREATE SCHEMA RandomSchema2;');
  CREATE TABLE RandomSchema1.SimpleTable1 (i INT);
  CREATE TABLE RandomSchema1.SimpleTable2 (i INT CONSTRAINT [s1t2pk] PRIMARY KEY);
  CREATE TABLE RandomSchema1.SimpleTable3 (i INT);

  CREATE TABLE RandomSchema2.SimpleTable1 (i INT);
  CREATE TABLE RandomSchema2.SimpleTable2 (i INT);
  CREATE TABLE RandomSchema2.SimpleTable3 (i INT);

  EXEC('CREATE PROCEDURE RandomSchema1.Proc1 AS RETURN;')
  EXEC('CREATE PROCEDURE RandomSchema1.Proc2 AS RETURN;')
  EXEC('CREATE PROCEDURE RandomSchema1.Proc3 AS RETURN;')


  SELECT O.object_id,SCHEMA_NAME(O.schema_id) schema_name, O.name object_name, O.type_desc 
    INTO #OriginalObjectIds
    FROM sys.objects O;

  EXEC tSQLt.FakeTable @TableName = 'RandomSchema1.SimpleTable1';
  CREATE TABLE UndoTestDoublesTests.SimpleTable1 (i INT);
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable1', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc1';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema1.SimpleTable1';
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable3';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc1';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema1.SimpleTable2';
  CREATE TABLE UndoTestDoublesTests.SimpleTable2 (i INT);
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable2', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;

  EXEC tSQLt.FakeTable @TableName = 'RandomSchema1.SimpleTable1';
  EXEC tSQLt.ApplyConstraint @TableName = 'RandomSchema1.SimpleTable2', @ConstraintName = 's1t2pk';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc1';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema2.SimpleTable3';
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.Proc3';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema1.SimpleTable2';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc1';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc2';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'RandomSchema1.Proc1';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema2.SimpleTable1';
  EXEC tSQLt.FakeTable @TableName = 'RandomSchema2.SimpleTable3';
  CREATE TABLE UndoTestDoublesTests.SimpleTable3 (i INT);
  EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = 'UndoTestDoublesTests.SimpleTable3', @ObjectType = 'TABLE', @NewNameOfOriginalObject = NULL;

  EXEC tSQLt.ApplyConstraint @TableName = 'RandomSchema1.SimpleTable2', @ConstraintName = 's1t2pk';
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable2';
  EXEC tSQLt.RemoveObject @ObjectName = 'RandomSchema1.SimpleTable1';

  EXEC tSQLt.UndoTestDoubles;

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
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE UndoTestDoublesTests.[test UndoTestDoubles error is appended to message]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO')
CREATE PROCEDURE UndoTestDoublesTests.[test UndoTestDoubles error causes Result to be set to Error]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO')
CREATE PROCEDURE UndoTestDoublesTests.[test HandleTables error is appended to message]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO')
CREATE PROCEDURE UndoTestDoublesTests.[test HandleTables error causes Result to be set to FATAL]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

/*--
TODO

--*/
--EXEC tSQLt.Run UndoTestDoublesTests