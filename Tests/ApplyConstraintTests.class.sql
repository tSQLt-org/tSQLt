EXEC tSQLt.NewTestClass 'ApplyConstraintTests';
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a check constraint to a fake table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaA.tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint can be called with 3 parameters]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA', 'tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaA.tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a check constraint to a fake table with schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO


CREATE PROC ApplyConstraintTests.[test ApplyConstraint can be called with 2 parameters]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO


CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a check constraint even if same table/constraint names exist on another schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaB');
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaB.testTable (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));
    CREATE TABLE schemaA.testTable (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaB.testTable';
    EXEC tSQLt.FakeTable 'schemaA.testTable';
    EXEC tSQLt.ApplyConstraint 'schemaB.testTable', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaB.testTable') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaB.testTable';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a check constraint even if same table/constraint names exist on multiple other schemata]
AS
BEGIN
  DECLARE @ActualDefinition VARCHAR(MAX);

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = (
  SELECT REPLACE(
          'EXEC (''CREATE SCHEMA schema?'');CREATE TABLE schema?.testTable (constCol INT CONSTRAINT testConstraint CHECK (constCol = 42));EXEC tSQLt.FakeTable ''schema?.testTable'';',
          '?',
          CAST(no AS NVARCHAR(MAX))
         )
    FROM tSQLt.F_Num(10)
    FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)');

  EXEC(@cmd);

  EXEC tSQLt.ApplyConstraint 'schema4.testTable', 'testConstraint';

  SELECT @ActualDefinition = definition
    FROM sys.check_constraints
   WHERE parent_object_id = OBJECT_ID('schema4.testTable') AND name = 'testConstraint';

  IF @@ROWCOUNT = 0
  BEGIN
      EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schema42.testTable';
  END;

  EXEC tSQLt.AssertEqualsString '([constCol]=(42))', @ActualDefinition;

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint throws error if called with invalid constraint]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.thisIsNotAConstraint (constCol CHAR(3) );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'thisIsNotAConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%ApplyConstraint could not resolve the object names, ''schemaA.tableA'', ''thisIsNotAConstraint''. Be sure to call ApplyConstraint and pass in two parameters, such as: EXEC tSQLt.ApplyConstraint ''MySchema.MyTable'', ''MyConstraint''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@ErrorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint throws error if called with constraint existsing on different table]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.tableB (constCol CHAR(3) CONSTRAINT MyConstraint CHECK (1=0));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'MyConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%ApplyConstraint could not resolve the object names%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@ErrorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a foreign key to a fake table with referenced table not faked]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);
    
    EXEC ('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (id int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(id));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('schemaA.tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a foreign key to a fake table with schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (id int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(id));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('schemaA.tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies a foreign key between two faked tables and insert works]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    INSERT INTO schemaA.tableA (aid) VALUES (13);
    INSERT INTO schemaA.tableB (aid) VALUES (13);
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies a foreign key between two faked tables and insert fails]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    DECLARE @msg NVARCHAR(MAX);
    SET @msg = 'No error message';
    
    BEGIN TRY
      INSERT INTO schemaA.tableB (aid) VALUES (13);
    END TRY
    BEGIN CATCH
      SET @msg = ERROR_MESSAGE();
    END CATCH
    
    IF @msg NOT LIKE '%testConstraint%'
    BEGIN
      EXEC tSQLt.Fail 'Expected Foreign Key to be applied, resulting in an FK error, however the actual error message was: ', @msg;
    END
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies a multi-column foreign key between two faked tables and insert works]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int, bid int, CONSTRAINT PK_tableA PRIMARY KEY (aid, bid));
    CREATE TABLE schemaA.tableB (cid int, aid int, bid int, CONSTRAINT testConstraint FOREIGN KEY (aid, bid) REFERENCES schemaA.tableA(aid, bid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    INSERT INTO schemaA.tableA (aid, bid) VALUES (13, 14);
    INSERT INTO schemaA.tableB (aid, bid) VALUES (13, 14);
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies a multi-column foreign key between two faked tables and insert fails]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int, bid int, CONSTRAINT PK_tableA PRIMARY KEY (aid, bid));
    CREATE TABLE schemaA.tableB (cid int, aid int, bid int, CONSTRAINT testConstraint FOREIGN KEY (aid, bid) REFERENCES schemaA.tableA(aid, bid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    DECLARE @msg NVARCHAR(MAX);
    SET @msg = 'No error message';
    
    INSERT INTO schemaA.tableA (aid, bid) VALUES (13, 13);
    INSERT INTO schemaA.tableA (aid, bid) VALUES (14, 14);
    
    BEGIN TRY
      INSERT INTO schemaA.tableB (aid, bid) VALUES (13, 14);
    END TRY
    BEGIN CATCH
      SET @msg = ERROR_MESSAGE();
    END CATCH
    
    IF @msg NOT LIKE '%testConstraint%'
    BEGIN
      EXEC tSQLt.Fail 'Expected Foreign Key to be applied, resulting in an FK error, however the actual error message was: ', @msg;
    END
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint does not create additional unique index on unfaked table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    DECLARE @NumberOfIndexes INT;
    SELECT @NumberOfIndexes = COUNT(1)
      FROM sys.indexes
     WHERE object_id = OBJECT_ID('schemaA.tableA');
     
    EXEC tSQLt.AssertEquals 1, @NumberOfIndexes;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint can apply two foreign keys]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, 
           aid1 int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid), 
           aid2 int CONSTRAINT testConstraint2 REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint2';
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint for a foreign key can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leA] ([id col] int PRIMARY KEY);
    CREATE TABLE [sche maA].[tab leB] ([bid col] int, [aid col] int CONSTRAINT [test Constraint] REFERENCES [sche maA].[tab leA]([id col]));

    EXEC tSQLt.FakeTable '[sche maA].[tab leA]';
    EXEC tSQLt.FakeTable '[sche maA].[tab leB]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leB]', '[test Constraint]';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'test Constraint' AND parent_object_id = OBJECT_ID('[sche maA].[tab leB]'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "test Constraint", was not copied to [tab leB]';
    END;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint for a check constraint can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leB] ([bid col] int CONSTRAINT [test Constraint] CHECK([bid col] > 5));

    EXEC tSQLt.FakeTable '[sche maA].[tab leB]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leB]', '[test Constraint]';

    IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name = 'test Constraint' AND parent_object_id = OBJECT_ID('[sche maA].[tab leB]'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "test Constraint", was not copied to [tab leB]';
    END;
END;
GO
