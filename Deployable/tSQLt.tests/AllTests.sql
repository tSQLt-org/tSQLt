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

CREATE PROC ApplyConstraintTests.[test ApplyConstraint of a foreign key does not create additional unique index on unfaked table]
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

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON UPDATE CASCADE]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON UPDATE CASCADE);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 142 WHERE aid = 42;

    SELECT B.bid,B.aid
    INTO #Actual
    FROM schemaA.tableB AS B;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES(1,142);
    INSERT INTO #Expected VALUES(2,142);

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON UPDATE SET NULL]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON UPDATE SET NULL);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 142 WHERE aid = 42;

    SELECT B.bid,B.aid
    INTO #Actual
    FROM schemaA.tableB AS B;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES(1,NULL);
    INSERT INTO #Expected VALUES(2,NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON UPDATE SET DEFAULT]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int NOT NULL
             CONSTRAINT testConstraintDC DEFAULT 7 
             CONSTRAINT testConstraintFC REFERENCES schemaA.tableA(aid) ON UPDATE SET DEFAULT
           );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB',@Defaults = 1;

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraintFC';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableA(aid)VALUES(7);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 13 WHERE aid = 42;

    SELECT B.bid,B.aid
    INTO #Actual
    FROM schemaA.tableB AS B;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES(1,7);
    INSERT INTO #Expected VALUES(2,7);

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON DELETE CASCADE]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON DELETE CASCADE);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    DELETE FROM schemaA.tableA;
    EXEC tSQLt.AssertEmptyTable @TableName = 'schemaA.tableB';
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON DELETE SET NULL]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON DELETE SET NULL);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    DELETE FROM schemaA.tableA;

    SELECT B.bid,B.aid
    INTO #Actual
    FROM schemaA.tableB AS B;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES(1,NULL);
    INSERT INTO #Expected VALUES(2,NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON DELETE SET DEFAULT]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int NOT NULL
             CONSTRAINT testConstraintDC DEFAULT 7 
             CONSTRAINT testConstraintFC REFERENCES schemaA.tableA(aid) ON DELETE SET DEFAULT
           );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB',@Defaults = 1;

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraintFC';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableA(aid)VALUES(7);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    DELETE FROM schemaA.tableA WHERE aid = 42;

    SELECT B.bid,B.aid
    INTO #Actual
    FROM schemaA.tableB AS B;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES(1,7);
    INSERT INTO #Expected VALUES(2,7);

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint Applies existing ON UPDATE and ON DELETE together]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int NOT NULL
             CONSTRAINT testConstraintDC DEFAULT 7 
             CONSTRAINT testConstraintFC REFERENCES schemaA.tableA(aid) ON UPDATE SET DEFAULT ON DELETE CASCADE
           );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB',@Defaults = 1;

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraintFC';

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableA(aid)VALUES(7);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 13 WHERE aid = 42;
    DELETE FROM schemaA.tableA WHERE aid = 7;

    EXEC tSQLt.AssertEmptyTable @TableName = 'schemaA.tableB';

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint doesn't apply existing ON DELETE CASCADE if @NoCascade = 1]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON DELETE CASCADE);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint @TableName = 'schemaA.tableB', @ConstraintName = 'testConstraint1', @NoCascade = 1;

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%DELETE%testConstraint1%';
    DELETE FROM schemaA.tableA;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint doesn't apply existing ON UPDATE CASCADE if @NoCascade = 1]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid) ON UPDATE CASCADE);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint @TableName = 'schemaA.tableB', @ConstraintName = 'testConstraint1', @NoCascade = 1;

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%UPDATE%testConstraint1%';
    UPDATE schemaA.tableA SET aid = 13 WHERE aid = 42;
END;
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint does apply existing ON UPDATE/DELETE CASCADE if @NoCascade = 0]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int NOT NULL
             CONSTRAINT testConstraintDC DEFAULT 7 
             CONSTRAINT testConstraintFC REFERENCES schemaA.tableA(aid) ON UPDATE SET DEFAULT ON DELETE CASCADE
           );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB',@Defaults = 1;

    EXEC tSQLt.ApplyConstraint @TableName = 'schemaA.tableB', @ConstraintName = 'testConstraintFC', @NoCascade = 0;

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableA(aid)VALUES(7);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 13 WHERE aid = 42;
    DELETE FROM schemaA.tableA WHERE aid = 7;

    EXEC tSQLt.AssertEmptyTable @TableName = 'schemaA.tableB';
END;
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint does apply existing ON UPDATE/DELETE CASCADE if @NoCascade = NULL]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid INT PRIMARY KEY, 
           aid int NOT NULL
             CONSTRAINT testConstraintDC DEFAULT 7 
             CONSTRAINT testConstraintFC REFERENCES schemaA.tableA(aid) ON UPDATE SET DEFAULT ON DELETE CASCADE
           );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB',@Defaults = 1;

    EXEC tSQLt.ApplyConstraint @TableName = 'schemaA.tableB', @ConstraintName = 'testConstraintFC', @NoCascade = NULL;

    INSERT INTO schemaA.tableA(aid)VALUES(42);
    INSERT INTO schemaA.tableA(aid)VALUES(7);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(1,42);
    INSERT INTO schemaA.tableB(bid,aid)VALUES(2,42);

    UPDATE schemaA.tableA SET aid = 13 WHERE aid = 42;
    DELETE FROM schemaA.tableA WHERE aid = 7;

    EXEC tSQLt.AssertEmptyTable @TableName = 'schemaA.tableB';
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

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a unique constraint to a fake table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint UNIQUE);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = ''
      FROM sys.key_constraints AS KC
     WHERE KC.parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaA.tableA';
    END;

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies unique constraint to correct column]
AS
BEGIN
    DECLARE @ActualColumns NVARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (Col1 INT, Col2 INT CONSTRAINT testConstraint UNIQUE, Col3 INT);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(1,1,1);
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(1,2,2);
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(3,3,2);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%testConstraint%';
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(4,3,4);

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint for a unique constrain can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leA] ([id col] INT CONSTRAINT[test constraint] UNIQUE);

    EXEC tSQLt.FakeTable '[sche maA].[tab leA]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leA]', '[test constraint]';

    IF NOT EXISTS(
                   SELECT 1 FROM sys.key_constraints AS KC 
                    WHERE name = 'test constraint' 
                      AND parent_object_id = OBJECT_ID('[sche maA].[tab leA]')
                 )
    BEGIN
        EXEC tSQLt.Fail 'Constraint [test constraint] was not copied to [tab leA]';
    END;
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies multi-column unique constraint]
AS
BEGIN
    DECLARE @ActualColumns NVARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (Col1 INT, Col2 INT, CONSTRAINT testConstraint UNIQUE(Col1, Col2));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,1);
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,2);
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(2,1);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%testConstraint%';
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,1);

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a primary key constraint to a fake table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint PRIMARY KEY);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT KC.name,OBJECT_NAME(KC.parent_object_id) AS parent_name,KC.type_desc
      INTO #Actual
      FROM sys.key_constraints AS KC
     WHERE KC.schema_id = SCHEMA_ID('schemaA')
       AND KC.name = 'testConstraint';

    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('testConstraint','tableA','PRIMARY_KEY_CONSTRAINT');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies primary key constraint to correct column]
AS
BEGIN
    DECLARE @ActualColumns NVARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (Col1 INT, Col2 INT CONSTRAINT testConstraint PRIMARY KEY, Col3 INT);

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(1,1,1);
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(1,2,2);
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(3,3,2);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%testConstraint%';
    INSERT INTO schemaA.tableA(Col1, Col2, Col3)VALUES(4,3,4);

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint for a primary key can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leA] ([id col] INT CONSTRAINT[test constraint] PRIMARY KEY);

    EXEC tSQLt.FakeTable '[sche maA].[tab leA]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leA]', '[test constraint]';

    SELECT KC.name,OBJECT_NAME(KC.parent_object_id) AS parent_name,KC.type_desc
      INTO #Actual
      FROM sys.key_constraints AS KC
     WHERE KC.schema_id = SCHEMA_ID('sche maA')
       AND KC.name = 'test constraint';

    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('test constraint','tab leA','PRIMARY_KEY_CONSTRAINT');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint applies multi-column primary key]
AS
BEGIN
    DECLARE @ActualColumns NVARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (Col1 INT, Col2 INT, CONSTRAINT testConstraint PRIMARY KEY(Col1, Col2));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,1);
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,2);
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(2,1);

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%testConstraint%';
    INSERT INTO schemaA.tableA(Col1, Col2)VALUES(1,1);

END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint copies a primary key and multiple unique constraints]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA 
    (col1 INT NOT NULL,
     col2 INT NULL,
     col3 INT NOT NULL,
     CONSTRAINT testConstraint1 PRIMARY KEY(col3,col1),
     CONSTRAINT testConstraint2 UNIQUE(col3,col2),
     CONSTRAINT testConstraint3 UNIQUE(col1,col2)
    );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint1';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint2';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint3';

    SELECT KC.name,OBJECT_NAME(KC.parent_object_id) AS parent_name,KC.type_desc
      INTO #Actual
      FROM sys.key_constraints AS KC
     WHERE KC.schema_id = SCHEMA_ID('schemaA')
       AND KC.name LIKE 'testConstraint_';

    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected VALUES('testConstraint1','tableA','PRIMARY_KEY_CONSTRAINT');
    INSERT INTO #Expected VALUES('testConstraint2','tableA','UNIQUE_CONSTRAINT');
    INSERT INTO #Expected VALUES('testConstraint3','tableA','UNIQUE_CONSTRAINT');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO



GO

EXEC tSQLt.NewTestClass 'ApplyTriggerTests';
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if table does not exist]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'ApplyTriggerTests.NotThere does not exist or was not faked by tSQLt.FakeTable.', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.NotThere', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if table is not a faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.NotAFakeTable(i INT);
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'ApplyTriggerTests.NotAFakeTable does not exist or was not faked by tSQLt.FakeTable.', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.NotAFakeTable', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if trigger does not exist]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithoutTrigger(i INT);
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithoutTrigger';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'AlsoNotThere is not a trigger on ApplyTriggerTests.TableWithoutTrigger', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithoutTrigger', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if trigger exist on wrong table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithoutTrigger(i INT);
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i INT);
  EXEC('CREATE TRIGGER MyTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithoutTrigger';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'MyTrigger is not a trigger on ApplyTriggerTests.TableWithoutTrigger', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithoutTrigger', @TriggerName = 'MyTrigger';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test trigger is applied to faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i iNT);
  EXEC('CREATE TRIGGER MyTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithTrigger';
  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithTrigger', @TriggerName = 'MyTrigger';
  
  CREATE TABLE #Actual(i INT IDENTITY(1,1));
  
  DELETE FROM ApplyTriggerTests.TableWithTrigger;
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'Trigger was not called!';
  
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test trigger is applied to faked table if all names require quoting]
AS
BEGIN
  EXEC('CREATE SCHEMA [very, odd: Schema!];');
  CREATE TABLE [very, odd: Schema!].[very, odd: Table!](i iNT);
  EXEC('CREATE TRIGGER [very, odd: Trigger!] ON [very, odd: Schema!].[very, odd: Table!] FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  
  EXEC tSQLt.FakeTable @TableName = '[very, odd: Schema!].[very, odd: Table!]';
  EXEC tSQLt.ApplyTrigger @TableName = '[very, odd: Schema!].[very, odd: Table!]', @TriggerName = '[very, odd: Trigger!]';
  
  CREATE TABLE #Actual(i INT IDENTITY(1,1));
  
  DELETE FROM [very, odd: Schema!].[very, odd: Table!];
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'Trigger was not called!';
  
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test correct trigger is applied to faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i iNT);
  EXEC('CREATE TRIGGER CorrectTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual VALUES(42);');
  EXEC('CREATE TRIGGER WrongTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual VALUES(13);');
  
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithTrigger';
  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithTrigger', @TriggerName = 'CorrectTrigger';
  
  CREATE TABLE #Actual(i INT);
  
  DELETE FROM ApplyTriggerTests.TableWithTrigger;
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(42);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'CorrectTrigger was not called!';
  
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertEmptyTableTests';
GO
CREATE TABLE AssertEmptyTableTests.TestTable(Id INT IDENTITY(1,1),Data1 VARCHAR(MAX));
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fail is not called when table is empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  
  EXEC tSQLt.AssertEmptyTable 'AssertEmptyTableTests.TestTable';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test handles odd names]
AS
BEGIN
  CREATE TABLE AssertEmptyTableTests.[TRANSACTION](Id INT);
  
  EXEC tSQLt.AssertEmptyTable 'AssertEmptyTableTests.TRANSACTION';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if table does not exist]
AS
BEGIN
  EXEC tSQLt.RemoveObject @ObjectName = 'AssertEmptyTableTests.TestTable';
  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';', '''AssertEmptyTableTests.TestTable'' does not exist';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if #table does not exist]
AS
BEGIN
  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''#doesnotexist'';', '''#doesnotexist'' does not exist';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if table is not empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  INSERT INTO AssertEmptyTableTests.TestTable(Data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test uses tSQLt.TableToText]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.TableToText','SET @txt = ''{TableToTextResult}'';';
  
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  INSERT INTO AssertEmptyTableTests.TestTable(Data1)
  VALUES('testdata');

  DECLARE @ExpectedFailMessage NVARCHAR(MAX); 
  SET @ExpectedFailMessage =   
  '[AssertEmptyTableTests].[TestTable] was not empty:'+CHAR(13)+CHAR(10)+
  '{TableToTextResult}';

  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';', @ExpectedFailMessage;
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with empty #temptable]
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

  EXEC tSQLt.AssertEmptyTable '#actual';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty #temptable]
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT #actual(data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''#actual'';';
END;
GO
--CREATE PROCEDURE AssertEmptyTableTests.[test works with empty quoted #temptable]
--AS
--BEGIN
--  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

--  EXEC tSQLt.AssertEmptyTable '[#actual]';
--END;
--GO
--CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty quoted #temptable]
--AS
--BEGIN
--  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
--  INSERT #actual(data1)
--  VALUES('testdata');

--  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''[#actual]'';';
--END;
--GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with empty quotable #temptable]
AS
BEGIN
  CREATE TABLE [#act'l](id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

  EXEC tSQLt.AssertEmptyTable '#act''l';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty quotable #temptable]
AS
BEGIN
  CREATE TABLE [#act'l](id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT [#act'l](data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''#act''''l'';';
END;
GO
CREATE PROC AssertEmptyTableTests.[test AssertEmptyTable should pass supplied message before original failure message when calling fail]
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT #actual(data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertEmptyTable ''#actual'',@Message = ''{MyMessage}'';', '%{MyMessage}%data1%testdata%';
END;
GO
CREATE PROC AssertEmptyTableTests.[test supplied message defaults to '']
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT #actual(data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertEmptyTable ''#actual'';', '[[]#actual]%';
END;
GO


GO

EXEC tSQLt.NewTestClass 'AsertEqualsStringTests';
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should do nothing with two equal VARCHAR Max Values]
AS
BEGIN
    DECLARE @TestString VARCHAR(Max);
    SET @TestString = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
    EXEC tSQLt.AssertEqualsString @TestString, @TestString;
END
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should do nothing with two NULLs]
AS
BEGIN
    EXEC tSQLt.AssertEqualsString NULL, NULL;
END
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should call fail with nonequal VARCHAR MAX]
AS
BEGIN
    DECLARE @TestString1 VARCHAR(MAX);
    SET @TestString1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'1';
    DECLARE @TestString2 VARCHAR(MAX);
    SET @TestString2 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'2';

    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString ''' + @TestString1 + ''', ''' + @TestString2 + ''';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should call fail with expected value and actual NULL]
AS
BEGIN
    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString ''1'', NULL;';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should call fail with expected NULL and actual value]
AS
BEGIN
    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString NULL, ''1'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString with expected NVARCHAR(MAX) and actual VARCHAR(MAX) of same value]
AS
BEGIN
    DECLARE @Expected NVARCHAR(MAX); SET @Expected = N'hello';
    DECLARE @Actual VARCHAR(MAX); SET @Actual = 'hello';
    EXEC tSQLt.AssertEqualsString @Expected, @Actual;
END;
GO

CREATE PROC AsertEqualsStringTests.[test AssertEqualsString should produce formatted fail message]
AS
BEGIN
  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = CHAR(13)+CHAR(10)+
                         'Expected: <Hello>'+CHAR(13)+CHAR(10)+
                         'but was : <World!>'

  EXEC tSQLt_testutil.AssertFailMessageEquals 
       'EXEC tSQLt.AssertEqualsString N''Hello'', N''World!'';',
       @ExpectedMessage;
END;
GO

CREATE PROC AsertEqualsStringTests.[test fail message shows NULL for expected value]
AS
BEGIN
  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = CHAR(13)+CHAR(10)+
                         'Expected: NULL'+CHAR(13)+CHAR(10)+
                         'but was : <>';

  EXEC tSQLt_testutil.AssertFailMessageEquals 
       'EXEC tSQLt.AssertEqualsString NULL,'''';',
       @ExpectedMessage;
END;
GO

CREATE PROC AsertEqualsStringTests.[test fail message shows NULL for actual value]
AS
BEGIN
  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = CHAR(13)+CHAR(10)+
                         'Expected: <>'+CHAR(13)+CHAR(10)+
                         'but was : NULL';

  EXEC tSQLt_testutil.AssertFailMessageEquals 
       'EXEC tSQLt.AssertEqualsString '''',NULL;',
       @ExpectedMessage;
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertEqualsTableSchemaTests';
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test does not fail if tables are identical]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'AssertEqualsTableSchemaTests.Tbl1', @Actual = 'AssertEqualsTableSchemaTests.Tbl2';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has missing column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has additional column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has renamed column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    Renamed INT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different data type]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different user data type]
AS
BEGIN
  CREATE TYPE AssertEqualsTableSchemaTests.TestType FROM NVARCHAR(256);

  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id INT PRIMARY KEY,
      NoKey NVARCHAR(256) NOT NULL
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id INT PRIMARY KEY,
      NoKey AssertEqualsTableSchemaTests.TestType NOT NULL
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test output contains type names]
AS
BEGIN
  CREATE TYPE AssertEqualsTableSchemaTests.TestType FROM INT;

  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id BIGINT PRIMARY KEY,
      NoKey INT
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id BIGINT PRIMARY KEY,
      NoKey AssertEqualsTableSchemaTests.TestType
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = '%56[[]int]%56[[]int]%'+CHAR(13)+CHAR(10)+
                         '%127[[]bigint]%127[[]bigint]%'+CHAR(13)+CHAR(10)+
                         '%56[[]int]%[[]AssertEqualsTableSchemaTests].[[]TestType]%'
  EXEC tSQLt_testutil.AssertFailMessageLike 
       @Command,@ExpectedMessage;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different NULLability]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NOT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different size]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(25) NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different precision]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,2)
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(17,2)
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different scale]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,2)
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,7)
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has different column order]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    NoKey INT,
    Id INT PRIMARY KEY
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different colation order]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey VARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CS_AS
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey VARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AI
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different user data type schema]
AS
BEGIN
  IF(SCHEMA_ID('A')IS NULL)EXEC('CREATE SCHEMA A;');
  IF(SCHEMA_ID('B')IS NULL)EXEC('CREATE SCHEMA B;');
  CREATE TYPE A.AssertEqualsTableSchemaTestType FROM INT;
  CREATE TYPE B.AssertEqualsTableSchemaTestType FROM INT;
  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id INT PRIMARY KEY,
      NoKey A.AssertEqualsTableSchemaTestType
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id INT PRIMARY KEY,
      NoKey B.AssertEqualsTableSchemaTestType
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail message starts with "Unexpected/missing columns\n"]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  DECLARE @Expected NVARCHAR(MAX); SET @Expected = 'Unexpected/missing column(s)'+CHAR(13)+CHAR(10)+'%';
  EXEC tSQLt_testutil.AssertFailMessageLike @Command, @Expected;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail message is prefixed with supplied message]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'', @Message=''{supplied message}'';';
  DECLARE @Expected NVARCHAR(MAX); SET @Expected = '{supplied message}%Unexpected%';
  EXEC tSQLt_testutil.AssertFailMessageLike @Command, @Expected;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test handles non-sequential column_id values]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    Col1 INT NULL, --2
    Gap1 INT NULL,
    Col2 INT NULL, --4
    Col3 INT NULL, --5
    Gap2 INT NULL,
    Gap3 INT NULL,
    Col4 INT NULL, --8
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    Col1 INT NULL, --2
    Col2 INT NULL, --3
    Gap1 INT NULL,
    Gap2 INT NULL,
    Col3 INT NULL, --6
    Col4 INT NULL, --7
  );
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap1;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap2;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap3;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl2 DROP COLUMN Gap1;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl2 DROP COLUMN Gap2;
  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'AssertEqualsTableSchemaTests.Tbl1', @Actual = 'AssertEqualsTableSchemaTests.Tbl2';
END;
GO

/*
SELECT 
    C.column_id,
    C.name,
    CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
    CAST(C.user_type_id AS NVARCHAR(MAX))+QUOTENAME(TU.name) user_type_id,
    C.max_length,
    C.precision,
    C.scale,
    C.collation_name,
    C.is_nullable,
    C.is_identity
  FROM sys.columns AS C
  JOIN sys.types AS TS
    ON C.system_type_id = TS.user_type_id
  JOIN sys.types AS TU
    ON C.user_type_id = TU.user_type_id


*/


GO

GO
EXEC tSQLt.NewTestClass 'AssertEqualsTableTests';
GO

CREATE PROCEDURE AssertEqualsTableTests.[test left table doesn't exist results in failure]
AS
BEGIN
  CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
  
  EXEC tSQLt_testutil.AssertFailMessageEquals
   'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.DoesNotExist'', ''AssertEqualsTableTests.RightTable''',
   '''AssertEqualsTableTests.DoesNotExist'' does not exist',
   'Expected AssertEqualsTable to fail.';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test right table doesn't exist results in failure]
AS
BEGIN
  CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
  
  EXEC tSQLt_testutil.AssertFailMessageEquals
   'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.DoesNotExist''',
   '''AssertEqualsTableTests.DoesNotExist'' does not exist',
   'Expected AssertEqualsTable to fail.';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test two tables with no rows and same schema are equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO
 
CREATE PROCEDURE AssertEqualsTableTests.CopyResultTable
@InResultTableName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SET @cmd = 'INSERT INTO AssertEqualsTableTests.ResultTable SELECT * FROM '+@InResultTableName;
  EXEC(@cmd);
END
GO
 
CREATE PROCEDURE AssertEqualsTableTests.[test left 1 row, right table 0 rows are not equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',1;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test right table 1 row, left table 0 rows are not equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '>',1;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test one row in each table, but row is different]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (13);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (42);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',13;
   
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '>',42;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same single row in each table]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same multiple rows in each table]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (2);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '>',2;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test compare table with two columns and no rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same single row in each table with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1, 2);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1, 2);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same multiple rows in each table with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1, 2);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3, 4);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1, 2);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3, 4);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (11, 12);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (31, 32);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (21, 22);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '=', 11, 12 UNION ALL
   SELECT '<', 31, 32 UNION ALL
   SELECT '>', 21, 22;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with mismatching column values in last column]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (11, 199);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '<', 11, 199 UNION ALL
   SELECT '>', 11, 12;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with mismatching column values in first column]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (199, 12);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '<', 199, 12 UNION ALL
   SELECT '>', 11, 12;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

--- At this point, AssertEqualsTable is tested enough we feel confident in using it in the remaining tests ---

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with multiple mismatching rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (5);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (4);
   
   CREATE TABLE AssertEqualsTableTests.ExpectedResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ExpectedResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '>',2 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '>',4 UNION ALL
   SELECT '<',5;
   
   CREATE TABLE AssertEqualsTableTests.ActualResultTable ([_m_] CHAR(1),i INT);
   EXEC tSQLt.Private_CompareTables 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable', 'AssertEqualsTableTests.ActualResultTable', 'i', '_m_';
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.ExpectedResultTable', 'AssertEqualsTableTests.ActualResultTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same row in each table but different row counts]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '<',3;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same row in each table but different row counts with more rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '=',1 UNION ALL
   SELECT '>',1 UNION ALL
   SELECT '>',1 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '<',3;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Create tables to compare]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  
  SET @Cmd = '
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a <<DATATYPE>>);
   CREATE TABLE AssertEqualsTableTests.LeftTable (a <<DATATYPE>>);
   CREATE TABLE AssertEqualsTableTests.RightTable (a <<DATATYPE>>);

   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a)
   SELECT e,v FROM(
    SELECT <<VALUES>>
   )X([=],[<],[>])
   UNPIVOT (v FOR e IN ([=],[<],[>])) AS u;
   ';
   
   SET @Cmd = REPLACE(@Cmd, '<<DATATYPE>>', @DataType);
   SET @Cmd = REPLACE(@Cmd, '<<VALUES>>', @Values);
   
   EXEC(@Cmd);
   
   
   INSERT INTO AssertEqualsTableTests.LeftTable (a)
   SELECT a FROM AssertEqualsTableTests.ResultTable WHERE [_m_] <> '>';

   INSERT INTO AssertEqualsTableTests.RightTable (a)
   SELECT a FROM AssertEqualsTableTests.ResultTable WHERE [_m_] <> '<';
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Drop tables to compare]
AS
BEGIN
   DROP TABLE AssertEqualsTableTests.ResultTable;  
   DROP TABLE AssertEqualsTableTests.LeftTable;  
   DROP TABLE AssertEqualsTableTests.RightTable;  
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
   EXEC AssertEqualsTableTests.[Create tables to compare] @DataType, @Values;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'Unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message for datatype ',
     @DataType,
     ':';
   
   EXEC AssertEqualsTableTests.[Drop tables to compare];
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test considers NULL values identical]
AS
BEGIN
  SELECT *
    INTO AssertEqualsTableTests.NullCellTableCopy
    FROM tSQLt.Private_NullCellTable;
  
  EXEC tSQLt.AssertEqualsTable 'tSQLt.Private_NullCellTable', 'AssertEqualsTableTests.NullCellTableCopy';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle integer data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BIT', '1,1,0';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'TINYINT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLINT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'INT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BIGINT', '10,11,12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle binary data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BINARY(1)', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARBINARY(2)', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARBINARY(MAX)', '0x10,0x11,0x12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle char data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'CHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NVARCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARCHAR(MAX)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NVARCHAR(MAX)', '''10'',''11'',''12''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle decimal data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DECIMAL(10,2)', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NUMERIC(10,2)', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLMONEY', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'MONEY', '0.10, 0.11, 0.12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle floating point data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'FLOAT', '1E-10, 1E-11, 1E-12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'REAL', '1E-10, 1E-11, 1E-12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle date data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLDATETIME', '''2012-01-01 12:00'',''2012-06-19 12:00'',''2012-10-25 12:00''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIME', '''2012-01-01 12:00'',''2012-06-19 12:00'',''2012-10-25 12:00''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle uniqueidentifier data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'UNIQUEIDENTIFIER', '''10101010-1010-1010-1010-101010101010'',''11111111-1111-1111-1111-111111111111'',''12121212-1212-1212-1212-121212121212''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle sql_variant data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', '''A'',''B'',''C''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', 'CAST(''2010-10-10'' AS DATETIME),CAST(''2011-11-11'' AS DATETIME),CAST(''2012-12-12'' AS DATETIME)';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle byte ordered comparable CLR data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'tSQLt_testutil.DataTypeByteOrdered', '''10'',''11'',''12''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
   EXEC AssertEqualsTableTests.[Create tables to compare] @DataType, @Values;
   
   DECLARE @Message NVARCHAR(MAX);
   SET @Message = 'No Error';

   BEGIN TRY
     EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   END TRY
   BEGIN CATCH
     SELECT @Message = ERROR_MESSAGE();
   END CATCH
   
   EXEC tSQLt.AssertLike '%The table contains a datatype that is not supported for tSQLt.AssertEqualsTable%Please refer to http://tsqlt.org/user-guide/assertions/assertequalstable/ for a list of unsupported datatypes%',@Message;

   EXEC AssertEqualsTableTests.[Drop tables to compare];
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test all unsupported data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'tSQLt_testutil.DataTypeNoEqual', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'tSQLt_testutil.DataTypeWithEqual', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'TEXT', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'NTEXT', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'IMAGE', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'XML', '''<X1 />'',''<X2 />'',''<X3 />''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'INT, c ROWVERSION', '0,0,0';--ROWVERSION is automatically valued
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test column name can be reserved word]
AS 
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable ([key] INT);
   CREATE TABLE AssertEqualsTableTests.RightTable ([key] INT);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test column name can contain garbage]
AS 
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable ([column with key G@r8'a9/;GO create table] INT);
   CREATE TABLE AssertEqualsTableTests.RightTable ([column with key G@r8'a9/;GO create table] INT);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test custom failure message is included in failure result]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',1;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   SET @ExpectedMessage = 'Custom failure message'+CHAR(13)+CHAR(10)+'Unexpected%';

   EXEC tSQLt_testutil.AssertFailMessageLike 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'', @Message = ''Custom failure message'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROC AssertEqualsTableTests.test_assertEqualsTable_raises_appropriate_error_if_expected_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.actual (constCol CHAR(3) );

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when expected table does not exist';
END;
GO

CREATE PROC AssertEqualsTableTests.test_assertEqualsTable_raises_appropriate_error_if_actual_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.expected (constCol CHAR(3) );
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when actual table does not exist';
END;
GO

CREATE PROC AssertEqualsTableTests.test_AssertEqualsTable_works_with_temptables
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    CREATE TABLE #T1(I INT)
    INSERT INTO #T1 SELECT 1
    CREATE TABLE #T2(I INT)
    INSERT INTO #T2 SELECT 2

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when comparing temp tables';
END;
GO

CREATE PROC AssertEqualsTableTests.test_AssertEqualsTable_works_with_equal_temptables
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT)
    INSERT INTO #T1 SELECT 42
    CREATE TABLE #T2(I INT)
    INSERT INTO #T2 SELECT 42
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC AssertEqualsTableTests.test_AssertEqualsTable_works_with_expected_having_identity_column
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT IDENTITY(1,1));
    INSERT INTO #T1 DEFAULT VALUES;
    CREATE TABLE #T2(I INT);
    INSERT INTO #T2 VALUES(1);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC AssertEqualsTableTests.test_AssertEqualsTable_works_with_actual_having_identity_column
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT);
    INSERT INTO #T1 VALUES(1);
    CREATE TABLE #T2(I INT IDENTITY(1,1));
    INSERT INTO #T2 DEFAULT VALUES;
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertEqualsTests';
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should do nothing with two equal ints]
AS
BEGIN
    EXEC tSQLt.AssertEquals 1, 1;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should do nothing with two NULLs]
AS
BEGIN
    EXEC tSQLt.AssertEquals NULL, NULL;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with nonequal ints]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, 2;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with expected int and actual NULL]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, NULL;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with expected NULL and actual int]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals NULL, 1;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals passes with various datatypes with the same value]
AS
BEGIN
    EXEC tSQLt.AssertEquals 12345.6789, 12345.6789;
    EXEC tSQLt.AssertEquals 'hello', 'hello';
    EXEC tSQLt.AssertEquals N'hello', N'hello';
    
    DECLARE @Datetime DATETIME; SET @Datetime = CAST('12-13-2005' AS DATETIME);
    EXEC tSQLt.AssertEquals @Datetime, @Datetime;
    
    DECLARE @Bit BIT; SET @Bit = CAST(1 AS BIT);
    EXEC tSQLt.AssertEquals @Bit, @Bit;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals fails with various datatypes of different values]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 12345.6789, 4321.1234', 'AssertEquals did not call Fail';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals ''hello'', ''goodbye''', 'AssertEquals did not call Fail';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals N''hello'', N''goodbye''', 'AssertEquals did not call Fail';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST(''12-13-2005'' AS DATETIME);
        DECLARE @Datetime2 DATETIME; SET @Datetime2 = CAST(''6-17-2005'' AS DATETIME);
        EXEC tSQLt.AssertEquals @Datetime1, @Datetime2;', 'AssertEquals did not call Fail';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
        DECLARE @Bit1 BIT; SET @Bit1 = CAST(1 AS BIT);
        EXEC tSQLt.AssertEquals @Bit0, @Bit1;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals with VARCHAR(MAX) throws error]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';

    BEGIN TRY
        DECLARE @V1 VARCHAR(MAX); SET @V1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
        EXEC tSQLt.AssertEquals @V1, @V1;
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH
    
    IF @Msg NOT LIKE '%Operand type clash%'
    BEGIN
        EXEC tSQLt.Fail 'Expected operand type clash error when AssertEquals used with VARCHAR(MAX), instead was: ', @Msg;
    END
    
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertLikeTests';
GO
CREATE PROC [AssertLikeTests].[test AssertLike fails when expectedPattern value IS NULL and actual value IS NOT NULL]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike NULL, ''1'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike fails when expectedPattern value IS NOT NULL and actual value IS NULL]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike ''Test'', NULL;';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike fails when single character expectedPattern does not match single character actual value]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike ''a'', ''z'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike succeeds when expectedPattern value IS NULL and actual value IS NULL]
AS
BEGIN
    EXEC tSQLt.AssertLike NULL, NULL;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports exact match]
AS
BEGIN
    EXEC tSQLt.AssertLike 'Exact match test.', 'Exact match test.';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard match]
AS
BEGIN
    EXEC tSQLt.AssertLike '%cat%', 'concatenate';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard range match]
AS
BEGIN
    EXEC tSQLt.AssertLike 'cr[a-d]ft', 'craft';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard characters as literals when escaped with brackets]
AS
BEGIN
    EXEC tSQLt.AssertLike '[[]object_schema].[[]object[_]name]', '[object_schema].[object_name]';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike fails literal match when wildcards in expectedPattern are not escaped]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike ''[quotedname]'', [quotedname];';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike errors when length of @ExpectedPattern is over 4000 characters]
AS
BEGIN
  DECLARE @Error NVARCHAR(MAX); SET @Error = '<No Error>';
  BEGIN TRY
    DECLARE @TooLongPattern NVARCHAR(MAX); SET @TooLongPattern = REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4001);
    EXEC tSQLt.AssertLike @TooLongPattern, '';
  END TRY
  BEGIN CATCH
    SET @Error =ERROR_MESSAGE();
  END CATCH;  
  
  EXEC tSQLt.AssertLike '%[@]ExpectedPattern may not exceed 4000 characters%', @Error;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike can handle length of @ExpectedPattern equal to 4000 characters]
AS
BEGIN
  DECLARE @NotTooLongPattern NVARCHAR(MAX); SET @NotTooLongPattern = REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4000);
  EXEC tSQLt.AssertLike @NotTooLongPattern, @NotTooLongPattern;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike can handle length of @Actual greater than 4000 characters]
AS
BEGIN
  DECLARE @LongActual NVARCHAR(MAX); 
  SET @LongActual = REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4000)+'cat'+
                    REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4000)+'mouse'+
                    REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4000);
  EXEC tSQLt.AssertLike '%cat%mouse%', @LongActual;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike returns helpful message on failure]
AS
BEGIN
	DECLARE @Command NVARCHAR(MAX); SET @Command = ' EXEC tSQLt.AssertLike ''craft'', ''cruft'';';
	EXEC tSQLt_testutil.AssertFailMessageEquals @Command, '
Expected: <craft>
 but was: <cruft>';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike allows custom failure message]
AS
BEGIN
	DECLARE @Command NVARCHAR(MAX); SET @Command = ' EXEC tSQLt.AssertLike ''craft'', ''cruft'', ''Custom Fail Message'';';
	EXEC tSQLt_testutil.AssertFailMessageEquals @Command, 'Custom Fail Message
Expected: <craft>
 but was: <cruft>';
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertNotEqualsTests';
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should do nothing with two unequal ints]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 0, 1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should call fail with equal ints]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals 1, 1;', 'AssertNotEquals did not call Fail';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should not call fail with expected null and nonnull actual]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals NULL,1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should not call fail with actual null and nonnull expected]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 1,NULL;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should call fail with equal nulls]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals NULL, NULL;', 'AssertNotEquals did not call Fail';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should give meaningfull fail message on NULL]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals NULL, NULL;', '%Expected actual value to not be NULL.%';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should pass message when calling fail]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 1, 1,''{MyMessage}'';', '%{MyMessage}%';
END;
GO
CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should pass supplied message before original failure message when calling fail]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 123654, 123654,''{MyMessage}'';', '%{MyMessage}%123654%';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals passes with various values of different datatypes]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 12345.6789, 4321.1234;
    EXEC tSQLt.AssertNotEquals 'hello', 'goodbye';
    EXEC tSQLt.AssertNotEquals N'hello', N'goodbye';
    
    DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST('12-13-2005' AS DATETIME);
    DECLARE @Datetime2 DATETIME; SET @Datetime2 = CAST('6-17-2005' AS DATETIME);
    EXEC tSQLt.AssertNotEquals @Datetime1, @Datetime2;
    
    DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
    DECLARE @Bit1 BIT; SET @Bit1 = CAST(1 AS BIT);
    EXEC tSQLt.AssertNotEquals @Bit0, @Bit1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals fails for equal values of various datatypes]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals 12345.6789, 12345.6789' ;
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals ''hello'', ''hello''';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals N''hello'', N''hello''';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST(''12-13-2005'' AS DATETIME);
        EXEC tSQLt.AssertNotEquals @Datetime1, @Datetime1;';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
        EXEC tSQLt.AssertNotEquals @Bit0, @Bit0;';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should give meaningfull failmessage]
AS
BEGIN
  EXEC tSQLt.RemoveObject 'tSQLt.Private_SqlVariantFormatter';
  EXEC('CREATE FUNCTION tSQLt.Private_SqlVariantFormatter(@Value SQL_VARIANT)RETURNS'+
       ' NVARCHAR(MAX) AS BEGIN DECLARE @msg NVARCHAR(MAX);SET @msg ='+
       '''{SVF was called with <''+CAST(@Value AS NVARCHAR(MAX))+''>}'';RETURN @msg; END;');

  EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 13, 13;', 
       'Expected actual value to not equal <{SVF was called with <13>}>.';
    
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals with VARCHAR(MAX) throws error]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';

    BEGIN TRY
        DECLARE @V1 VARCHAR(MAX); SET @V1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
        EXEC tSQLt.AssertNotEquals @V1, @V1;
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH
    
    IF @Msg NOT LIKE '%Operand type clash%'
    BEGIN
        EXEC tSQLt.Fail 'Expected operand type clash error when AssertEquals used with VARCHAR(MAX), instead was: ', @Msg;
    END
    
END;
GO



GO

EXEC tSQLt.NewTestClass 'AssertObjectDoesNotExistTests';
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object exists]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.aTable(id INT);
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''schemaA.aTable''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object exists and is not a table]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    EXEC ('CREATE VIEW schemaA.aView AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''schemaA.aView''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test does not call fail if object does not exist]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    EXEC tSQLt.AssertObjectDoesNotExist 'schemaA.doesNotExist';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object is #temp object]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''#aTempObject''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test uses appropriate fail message]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''#aTempObject''';
    EXEC tSQLt_testutil.AssertFailMessageEquals @Command = @Command, @ExpectedMessage = '''#aTempObject'' does exist!'
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test allows for additional @Message]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist @ObjectName = ''#aTempObject'', @Message = ''Some additional message!''';
    EXEC tSQLt_testutil.AssertFailMessageLike @Command = @Command, @ExpectedMessage = 'Some additional message!%'
END;
GO


GO

EXEC tSQLt.NewTestClass 'AssertObjectExistsTests';
GO
CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_raises_appropriate_error_if_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectExists ''schemaA.expected''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectExists did not call Fail when table does not exist';
END;
GO

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_does_not_call_fail_when_table_exists
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.tbl(i int);');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_does_not_call_fail_when_table_is_temp_table
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #Tbl(i int);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''#Tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'DropClassTests';
GO
CREATE PROC DropClassTests.test_dropClass_does_not_error_if_testcase_name_contains_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A ] AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.DropClass 'MyTestClass';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH

    EXEC tSQLt.AssertEquals 0,@ErrorRaised,'Unexpected error during execution of DropClass'
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes UDDTs]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes UDDTs after tables]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');
    EXEC('CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT);');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes XML Schemata]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE XML SCHEMA COLLECTION MyTestClass.TestXMLSchema
    AS''<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"><xsd:element name="testelement" /></xsd:schema>'';');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO

CREATE PROC DropClassTests.[test removes class with spaces in name]
AS
BEGIN
    EXEC('CREATE SCHEMA [My Test Class];');

    EXEC tSQLt.ExpectNoException;
        EXEC tSQLt.DropClass 'My Test Class';
    
    IF(SCHEMA_ID('My Test Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My Test Class]';
    END
END;
GO

CREATE PROC DropClassTests.[test removes class if name is passed quoted]
AS
BEGIN
    EXEC('CREATE SCHEMA [My Test Class];');

    EXEC tSQLt.ExpectNoException;
        EXEC tSQLt.DropClass '[My Test Class]';
    
    IF(SCHEMA_ID('My Test Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My Test Class]';
    END
END;
GO





GO

EXEC tSQLt.NewTestClass 'ExpectExceptionTests';
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException causes test without exception to fail ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException with no parms produces default fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException','Expected an error to be raised.';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting exception passes when error is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;RAISERROR(''X'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message fails when different message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message passes when correct message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Correct Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message can contain wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct [Msg]'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong message produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Message: <Correct Message>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong Message>';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;

END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting severity fails when unexpected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity = 13;RAISERROR(''Message'',15,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting severity succeeds when expected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity = 13;RAISERROR(''Message'',13,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting state fails when unexpected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState = 7;RAISERROR(''Message'',15,6);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting state passes when expected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState = 7;RAISERROR(''Message'',15,7);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong severity produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Severity: 13'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 14';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong state produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected State: 13'+CHAR(13)+CHAR(10)+
                           'Actual State  : 10';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting MessagePattern handles wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessagePattern = ''Cor[rt]ect%'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes additional message]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage=''Correct'', @Message=''Additional Fail Message.'';RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message: <Correct>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong>';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes additional message if no other expectations]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Message=''Additional Fail Message.'';');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Expected an error to be raised.';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test fails if called more then once]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyTestClass';
  EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS  EXEC tSQLt.ExpectException;EXEC tSQLt.ExpectException;');

  EXEC tSQLt_testutil.AssertTestErrors 'MyTestClass.TestExpectingNoException','Each test can only contain one call to tSQLt.ExpectException.%';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting error number fails when unexpected error number is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001;RAISERROR(''Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting error number passes when expected error number is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50000;RAISERROR(''Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong error number produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001;RAISERROR(''Message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001,@ExpectedMessage=''Correct'',@ExpectedSeverity=11,@ExpectedState=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message: <Correct>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part including the MessagePattern]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001,@ExpectedMessagePattern=''Cor[rt]ect'',@ExpectedSeverity=11,@ExpectedState=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message to be like <Cor[[]rt]ect>'+CHAR(13)+CHAR(10)+
                           'Actual Message            : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO

CREATE PROCEDURE ExpectExceptionTests.[test a single ExpectNoException can be followed by a single ExpectException]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS  EXEC tSQLt.ExpectNoException;EXEC tSQLt.ExpectException;RAISERROR(''X'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO

CREATE PROCEDURE ExpectExceptionTests.[test an error after ExpectNoException but before ExpectException fails the test]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS  EXEC tSQLt.ExpectNoException;RAISERROR(''X'',16,10);EXEC tSQLt.ExpectException;');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO


GO

EXEC tSQLt.NewTestClass 'ExpectNoExceptionTests';
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test does not fail if no exception is encountered]
AS
BEGIN
  EXEC tSQLt.ExpectNoException;
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException causes test with exception to fail ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException;RAISERROR(''testerror'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException';
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException includes error information in fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException;RAISERROR(''test error message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Expected no error to be raised. Instead this error was encountered:'+CHAR(13)+CHAR(10)+
                           'test error message[[]16,10]{TestExpectingNoException,1}';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException', @ExpectedMessage;
END;
GO

CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException includes additional message in fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException @Message=''Additional Fail Message.'';RAISERROR(''test error message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Expected no error to be raised. Instead %';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException', @ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test fails if called more then once]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyTestClass';
  EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS  EXEC tSQLt.ExpectNoException;EXEC tSQLt.ExpectNoException;');

  EXEC tSQLt_testutil.AssertTestErrors 'MyTestClass.TestExpectingNoException','Each test can only contain one call to tSQLt.ExpectNoException.%';
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test a ExpectNoException cannot follow an ExpectException]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyTestClass';
  EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS  EXEC tSQLt.ExpectException;EXEC tSQLt.ExpectNoException;');

  EXEC tSQLt_testutil.AssertTestErrors 'MyTestClass.TestExpectingNoException','tSQLt.ExpectNoException cannot follow tSQLt.ExpectException inside a single test.%';
END;
GO



GO

EXEC tSQLt.NewTestClass 'FailTests';
GO

CREATE PROCEDURE FailTests.[InvalidateTransaction]
AS
BEGIN
  BEGIN TRY
    DECLARE @i INT ;
    SET @i = 'NAN';
  END TRY
  BEGIN CATCH
  END CATCH;
END;
GO

CREATE PROC FailTests.[test Fail rolls back transaction if transaction is unable to be committed]
AS
BEGIN
  DECLARE @ErrorMessage NVARCHAR(MAX);
  SET @ErrorMessage = 'No Error Thrown';

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
  END CATCH;

  EXEC tSQLt.AssertEqualsString 'tSQLt.Failure', @ErrorMessage;
END;
GO

CREATE PROC FailTests.[test Fail does not change open tansaction count in case of XACT_STATE = -1]
AS
BEGIN
  DECLARE @ErrorMessage NVARCHAR(MAX);
  SET @ErrorMessage = 'No Error Thrown';

  BEGIN TRAN;

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
  END CATCH;
  
  COMMIT;

  EXEC tSQLt.AssertEqualsString 'tSQLt.Failure', @ErrorMessage;
END;
GO

CREATE PROC FailTests.[test Fail recreates savepoint if it has to clean up transactions]
AS
BEGIN
  DECLARE @TranName NVARCHAR(MAX);
  SELECT @TranName = TranName
    FROM tSQLt.TestResult
   WHERE Id = (SELECT MAX(Id) FROM tSQLt.TestResult);

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
  END CATCH;

  BEGIN TRY
    ROLLBACK TRAN @TranName;
  END TRY
  BEGIN CATCH
    EXEC tSQLt.Fail 'Expected to be able to rollback the named transaction';
  END CATCH;
END;
GO

CREATE PROC FailTests.[test Fail gives info about cleanup work if transaction state is invalidated]
AS
BEGIN
  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
  END CATCH;

  DECLARE @TestResultMessage NVARCHAR(MAX);
  SELECT @TestResultMessage = Msg
    FROM tSQLt.TestMessage;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = '%Not really a failure - just seeing that fail works%'+CHAR(13)+CHAR(10)+'Warning: Uncommitable transaction detected!%'
  EXEC tSQLt.AssertLike @ExpectedMessage, @TestResultMessage;
END;
GO


GO

EXEC tSQLt.NewTestClass 'FakeFunctionTests';
GO
CREATE PROCEDURE FakeFunctionTests.[test scalar function can be faked]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS INT AS BEGIN RETURN 13; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS INT AS BEGIN RETURN 42; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
  DECLARE @Actual INT;SET @Actual = FakeFunctionTests.AFunction();
  
  EXEC tSQLt.AssertEquals @Expected = 42, @Actual = @Actual;
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test tSQLt.Private_GetFullTypeName is used for return type]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NUMERIC(30,2) AS BEGIN RETURN 30.2; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS NUMERIC(30,2) AS BEGIN RETURN 29.3; END;');
  
  EXEC tSQLt.RemoveObject @ObjectName = 'tSQLt.Private_GetFullTypeName';
  EXEC('CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))'+
       ' RETURNS TABLE AS RETURN SELECT ''NUMERIC(25,7)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 108 AND @Length = 17 AND @Precision = 30 AND @Scale = 2;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  SELECT user_type_id, precision, scale 
    INTO #Actual
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('FakeFunctionTests.AFunction')
     AND parameter_id = 0;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(108,25,7);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test tSQLt.Private_GetFullTypeName is used to build parameter list]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NUMERIC(10,1),@p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 NUMERIC(10,1),@p2 VARCHAR(MAX)) RETURNS VARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  
  EXEC tSQLt.RemoveObject @ObjectName = 'tSQLt.Private_GetFullTypeName';
  EXEC('CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))'+
       ' RETURNS TABLE AS RETURN '+
       'SELECT ''NUMERIC(25,7)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 108 AND @Precision = 10 AND @Scale = 1'+
       ' UNION ALL '+
       'SELECT ''VARCHAR(19)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 231 AND @Length = -1 ;'
       );
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  SELECT parameter_id,user_type_id,max_length,precision, scale 
    INTO #Actual
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('FakeFunctionTests.AFunction')
     AND parameter_id > 0;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected VALUES(1,108,13,25,7);
  INSERT INTO #Expected VALUES(2,167,19,0,0);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Parameters are passed through to fake funktion]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 INT,@p2 NVARCHAR(MAX),@p3 DATETIME) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 INT,@p2 NVARCHAR(MAX),@p3 DATETIME) RETURNS NVARCHAR(MAX) AS BEGIN RETURN '+
                                              '''|''+CAST(@p1 AS NVARCHAR(MAX))+''|''+@p2+''|''+CONVERT(NVARCHAR(MAX),@p3,121)+''|''; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = FakeFunctionTests.AFunction(392844,'AString','2013-12-11 10:09:08.070');
  
  EXEC tSQLt.AssertEqualsString @Expected = '|392844|AString|2013-12-11 10:09:08.070|', @Actual = @Actual;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function doesn't exist]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'FakeFunctionTests.ANotExistingFunction does not exist!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.ANotExistingFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when fake function doesn't exist]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'FakeFunctionTests.ANotExistingFakeFunction does not exist!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.ANotExistingFakeFunction';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Fake can be CLR function]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrSvf';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = FakeFunctionTests.AFunction('ABC','DEF');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'AClrSvf:[ABC|DEF]', @Actual = @Actual;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Fakee can be CLR function]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN @p1+''<fake>''+@p2; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt_testutil.AClrSvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = tSQLt_testutil.AClrSvf('ABC','DEF');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'ABC<fake>DEF', @Actual = @Actual;
END;
GO
CREATE FUNCTION FakeFunctionTests.[An SVF]() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''; END;
GO
CREATE FUNCTION FakeFunctionTests.[A MSTVF]() RETURNS @r TABLE(r NVARCHAR(MAX)) AS BEGIN RETURN; END;
GO
CREATE FUNCTION FakeFunctionTests.[An ITVF]() RETURNS TABLE AS RETURN SELECT ''r;
GO
CREATE TABLE FakeFunctionTests.[A Table] (id INT);
GO
CREATE PROCEDURE FakeFunctionTests.[Assert errors on function type mismatch]
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Both parameters must contain the name of either scalar or table valued functions!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = @FunctionName, @FakeFunctionName = @FakeFunctionName;  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is MSTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[A MSTVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is ITVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[An ITVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is CLRTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[Assert TVF can be faked]
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = @FunctionName, @FakeFunctionName = @FakeFunctionName;

  CREATE TABLE #Actual(id INT, val NVARCHAR(MAX))
  
  EXEC('INSERT INTO #Actual SELECT * FROM '+@FunctionName+'(''ABC'',''DEF'');')
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected VALUES(1,'ABC');
  INSERT INTO #Expected VALUES(2,'DEF');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF WITH CLR TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH CLR TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF WITH CLR TVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is MSTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[A MSTVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is ITVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[An ITVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is CLRTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when fakee is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A Table]','FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[assert parameter missmatch causes error]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Parameters of both functions must match! (This includes the return type for scalar functions.)', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in name]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@di INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in max_length]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id CHAR(2)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id CHAR(3)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in precision]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id NUMERIC(10,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id NUMERIC(11,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in scale]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id NUMERIC(10,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id NUMERIC(10,2)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in their order]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id1 INT, @id2 INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id2 INT, @id1 INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when type of return value for scalar functions doesn't match]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(10) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction() RETURNS NVARCHAR(20) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO



GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

EXEC tSQLt.NewTestClass 'FakeTableTests';
GO

CREATE PROC FakeTableTests.[test that no disabled tests exist]
AS
BEGIN
  SELECT name 
  INTO #Actual
  FROM sys.procedures
  WHERE (
     LOWER(name) LIKE '_test%'
  OR LOWER(name) LIKE 't_est%'
  OR LOWER(name) LIKE 'te_st%'
  OR LOWER(name) LIKE 'tes_t%'
  )
  AND schema_id = SCHEMA_ID(OBJECT_SCHEMA_NAME(@@PROCID));
  
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints
@TableName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @OldTableObjectId INT;

  IF OBJECT_ID(@TableName) IS NULL
    EXEC tSQLt.Fail 'Table ',@TableName,' does not exist!';

  SELECT @OldTableObjectId = OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(major_id))+'.'+QUOTENAME(CAST(value AS NVARCHAR(4000))))
  FROM sys.extended_properties WHERE major_id = OBJECT_ID(@TableName) and name = 'tSQLt.FakeTable_OrgTableName'

  IF @OldTableObjectId IS NULL
    EXEC tSQLt.Fail 'Table ',@TableName,' is not a fake table!';
  
  IF OBJECT_ID(@TableName) = @OldTableObjectId
    EXEC tSQLt.Fail 'Table ',@TableName,' is not a new object!';
    
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id))+'.'+QUOTENAME(OBJECT_NAME(object_id)) ReferencingObjectName 
  INTO #actual FROM sys.objects WHERE parent_object_id = OBJECT_ID(@TableName);
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual','Unexpected referencing objects found!';
END
GO

CREATE PROC FakeTableTests.[test FakeTable works with 2 part names in first parameter]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT);
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable takes 2 nameless parameters containing schema and table name]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT);
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable raises appropriate error if table does not exist]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaA.tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaA.tableXYZ''. (When calling tSQLt.FakeTable, avoid the use of the @SchemaName parameter, as it is deprecated.)%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable raises appropriate error if schema does not exist]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaB.tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''.%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable raises appropriate error if called with NULL parameters]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable NULL;
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''(null)''.%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable raises appropriate error if it was called with a single parameter]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaB.tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''.%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC FakeTableTests.[test a faked table has no primary key]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT PRIMARY KEY);
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC FakeTableTests.[test a faked table has no check constraints]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT CHECK(i > 5));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC FakeTableTests.[test a faked table has no foreign keys]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable0(i INT PRIMARY KEY);
  CREATE TABLE FakeTableTests.TempTable1(i INT REFERENCES FakeTableTests.TempTable0(i));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any defaults removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT DEFAULT(77));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) DEFAULT VALUES;
  
  DECLARE @value INT;
  SELECT @value = i
    FROM FakeTableTests.TempTable1;
    
  EXEC tSQLt.AssertEquals NULL, @value;
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any unique constraints removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT UNIQUE);
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any unique indexes removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT);
  CREATE UNIQUE INDEX UQ_tSQLt_test_TempTable1_i ON FakeTableTests.TempTable1(i);
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any not null constraints removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT NOT NULL);
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (NULL);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable works on referencedTo tables]
AS
BEGIN
  IF OBJECT_ID('FakeTableTests.tst1') IS NOT NULL DROP TABLE tst1;
  IF OBJECT_ID('FakeTableTests.tst2') IS NOT NULL DROP TABLE tst2;

  CREATE TABLE FakeTableTests.tst1(i INT PRIMARY KEY);
  CREATE TABLE FakeTableTests.tst2(i INT PRIMARY KEY, tst1i INT REFERENCES FakeTableTests.tst1(i));
  
  BEGIN TRY
    EXEC tSQLt.FakeTable 'FakeTableTests.tst1';
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX);
    SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';

    EXEC tSQLt.Fail 'FakeTable threw unexpected error:', @ErrorMessage;
  END CATCH;
END;
GO

CREATE PROC FakeTableTests.[test FakeTable doesn't produce output]
AS
BEGIN
  CREATE TABLE FakeTableTests.tst(i INT);
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.FakeTable ''FakeTableTests.tst''';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable doesn't preserve identity if @Identity parameter is not specified]
AS
BEGIN
  IF OBJECT_ID('FakeTableTests.tst1') IS NOT NULL DROP TABLE FakeTableTests.tst1;

  CREATE TABLE FakeTableTests.tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.tst1';
  
  IF EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('FakeTableTests.tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has identity column!';
  END
END;
GO

CREATE PROC FakeTableTests.[test FakeTable doesn't preserve identity if @identity parameter is 0]
AS
BEGIN
  IF OBJECT_ID('FakeTableTests.tst1') IS NOT NULL DROP TABLE FakeTableTests.tst1;

  CREATE TABLE FakeTableTests.tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.tst1',@Identity=0;
  
  IF EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('FakeTableTests.tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has identity column!';
  END
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves identity if @identity parameter is 1]
AS
BEGIN
  IF OBJECT_ID('FakeTableTests.tst1') IS NOT NULL DROP TABLE FakeTableTests.tst1;

  CREATE TABLE FakeTableTests.tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'FakeTableTests.tst1',@Identity=1;
  
  IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('FakeTableTests.tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has no identity column!';
  END
END;
GO


CREATE PROC FakeTableTests.[test FakeTable works with more than one column]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(i1 INT,i2 INT,i3 INT,i4 INT,i5 INT,i6 INT,i7 INT,i8 INT);

  SELECT column_id,name
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1')
  
  EXEC tSQLt.FakeTable 'dbo.tst1';

  SELECT column_id,name
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1')

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
 
CREATE PROC FakeTableTests.[test FakeTable works with ugly column and table names]
AS
BEGIN
  IF OBJECT_ID('dbo.[tst!@#$%^&*()_+ 1]') IS NOT NULL DROP TABLE dbo.[tst!@#$%^&*()_+ 1];

  CREATE TABLE dbo.[tst!@#$%^&*()_+ 1]([col!@#$%^&*()_+ 1] INT);

  SELECT column_id,name
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.[tst!@#$%^&*()_+ 1]')
  
  EXEC tSQLt.FakeTable 'dbo.[tst!@#$%^&*()_+ 1]';

  SELECT column_id,name
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.[tst!@#$%^&*()_+ 1]')

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves identity base and step-size]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(i INT IDENTITY(42,13));
  INSERT INTO dbo.tst1 DEFAULT VALUES;
  INSERT INTO dbo.tst1 DEFAULT VALUES;

  SELECT i 
    INTO #Expected
    FROM dbo.tst1;
  
  EXEC tSQLt.FakeTable 'dbo.tst1',@Identity=1;
  
  INSERT INTO dbo.tst1 DEFAULT VALUES;
  INSERT INTO dbo.tst1 DEFAULT VALUES;
  
  EXEC tSQLt.AssertEqualsTable '#Expected', 'dbo.tst1';
  
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves data type of identity column with @Identity=0]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(i BIGINT IDENTITY(1,1));

  SELECT TYPE_NAME(user_type_id) type_name
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');
  
  EXEC tSQLt.FakeTable 'dbo.tst1',@Identity = 0;

  SELECT TYPE_NAME(user_type_id) type_name
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves data type of identity column with @Identity=1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(i [DECIMAL](4) IDENTITY(1,1));

  SELECT TYPE_NAME(user_type_id) type_name,max_length,precision,scale
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');
  
  EXEC tSQLt.FakeTable 'dbo.tst1',@Identity = 1;

  SELECT TYPE_NAME(user_type_id) type_name,max_length,precision,scale
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.[test FakeTable works if IDENTITYCOL is not the first column (with @Identity=1)]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, i INT IDENTITY(1,1), y VARCHAR(30));

  SELECT name, is_identity
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');
  
  EXEC tSQLt.FakeTable 'dbo.tst1',@Identity = 1;

  SELECT name, is_identity
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.[test FakeTable works if there is no IDENTITYCOL and @Identity = 1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, y VARCHAR(30));

  SELECT name, is_identity
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');
  
  EXEC tSQLt.FakeTable 'dbo.tst1',@Identity = 1;

  SELECT name, is_identity
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForComputedCols
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX),
   @ClearComputedCols INT
AS
BEGIN
  SELECT c.column_id, CASE WHEN cc.column_id IS NULL THEN 0 ELSE 1 END AS IsComputedColumn, cc.is_persisted, c.name, cc.definition, c.user_type_id
    INTO #Expected
    FROM sys.columns c
    LEFT OUTER JOIN sys.computed_columns cc ON cc.object_id = c.object_id
                                              AND cc.column_id = c.column_id
                                              AND @ClearComputedCols = 0
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC (@Cmd);  

  SELECT c.column_id, CASE WHEN cc.column_id IS NULL THEN 0 ELSE 1 END AS IsComputedColumn, cc.is_persisted, c.name, cc.definition, c.user_type_id
    INTO #Actual
    FROM sys.columns c
    LEFT OUTER JOIN sys.computed_columns cc ON cc.object_id = c.object_id
                                              AND cc.column_id = c.column_id
   WHERE c.object_id = OBJECT_ID('dbo.tst1');
   
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForComputedCols
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX)
AS
BEGIN
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForComputedCols @TableName, @Cmd, 0;
END
GO

CREATE PROC FakeTableTests.AssertTableAfterCommandHasNoComputedCols
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX)
AS
BEGIN
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForComputedCols @TableName, @Cmd, 1;
END
GO

CREATE PROC FakeTableTests.[test FakeTable preserves computed columns if @ComputedColumns = 1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, y AS x + 5);
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForComputedCols 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @ComputedColumns = 1;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves persisted computed columns if @ComputedColumns = 1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, y AS x + 5 PERSISTED);
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForComputedCols 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @ComputedColumns = 1;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable does not preserve persisted computed columns if @ComputedColumns = 0]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, y AS x + 5 PERSISTED);

  EXEC FakeTableTests.AssertTableAfterCommandHasNoComputedCols 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @ComputedColumns = 0;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable does not preserve persisted computed columns if @ComputedColumns is not specified]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT, y AS x + 5 PERSISTED);

  EXEC FakeTableTests.AssertTableAfterCommandHasNoComputedCols 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'';';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves multiple mixed persisted computed columns if @ComputedColumns = 1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(NotComputed INT, ComputedAndPersisted AS (NotComputed + 5) PERSISTED, ComputedNotPersisted AS (NotComputed + 7), AnotherComputed AS (GETDATE()));
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForComputedCols 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @ComputedColumns = 1;';
END;
GO

CREATE PROC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForDefaults
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX),
   @ClearDefaults INT
AS
BEGIN
  SELECT c.column_id, CASE WHEN dc.parent_column_id IS NULL THEN 0 ELSE 1 END AS IsComputedColumn, c.name, dc.definition, c.user_type_id
    INTO #Expected
    FROM sys.columns c
    LEFT OUTER JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id
                                              AND dc.parent_column_id = c.column_id
                                              AND @ClearDefaults = 0
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC (@Cmd);  

  SELECT c.column_id, CASE WHEN dc.parent_column_id IS NULL THEN 0 ELSE 1 END AS IsComputedColumn, c.name, dc.definition, c.user_type_id
    INTO #Actual
    FROM sys.columns c
    LEFT OUTER JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id
                                              AND dc.parent_column_id = c.column_id
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForDefaults
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX)
AS
BEGIN
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForDefaults @TableName, @Cmd, 0;
END
GO

CREATE PROC FakeTableTests.AssertTableAfterCommandHasNoDefaults
   @TableName NVARCHAR(MAX),
   @Cmd NVARCHAR(MAX)
AS
BEGIN
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandForDefaults @TableName, @Cmd, 1;
END
GO

CREATE PROC FakeTableTests.[test FakeTable does not preserve defaults if @Defaults is not specified]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT DEFAULT(5));
  
  EXEC FakeTableTests.AssertTableAfterCommandHasNoDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1''';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable does not preserve defaults if @Defaults = 0]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT DEFAULT(5));

  EXEC FakeTableTests.AssertTableAfterCommandHasNoDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @Defaults = 0;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves defaults if @Defaults = 1]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT DEFAULT(5));
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @Defaults = 1;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves defaults if @Defaults = 1 when multiple columns exist on table]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(
    ColWithNoDefault CHAR(3),
    ColWithDefault DATETIME DEFAULT(GETDATE())
  );
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @Defaults = 1;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves defaults if @Defaults = 1 when multiple varied columns exist on table]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(
    ColWithNoDefault CHAR(3),
    ColWithDefault DATETIME DEFAULT(GETDATE()),
    ColWithDiffDefault INT DEFAULT(-3)
  );
  
  EXEC FakeTableTests.AssertTableStructureBeforeAndAfterCommandIsSameForDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''dbo.tst1'', @Defaults = 1;';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves the collation of a column]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x VARCHAR(30) COLLATE Latin1_General_BIN,
                        y VARCHAR(40));

  SELECT name, collation_name
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');
  
  EXEC tSQLt.FakeTable 'dbo.tst1';

  SELECT name, collation_name
    INTO #Actual
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns quoted schema when schema and table provided]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT @CleanSchemaName = CleanSchemaName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString '[MySchema]', @CleanSchemaName;
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility can handle quoted names]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('[MyTable]', '[MySchema]');
    
  SELECT TOP(0)* INTO #expected FROM #actual;
  
  INSERT INTO #expected(CleanSchemaName, CleanTableName) VALUES('[MySchema]','[MyTable]');

  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns quoted table when schema and table provided]
AS
BEGIN
  DECLARE @CleanTableName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT @CleanTableName = CleanTableName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString '[MyTable]', @CleanTableName;
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULL schema name when table does not exist]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
          
  SELECT @CleanSchemaName = CleanSchemaName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString NULL, @CleanSchemaName;
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULL table name when table does not exist]
AS
BEGIN
  DECLARE @CleanTableName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
          
  SELECT @CleanTableName = CleanTableName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString NULL, @CleanTableName;
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULLs when table name has special char]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.[.MyTable] (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('.MyTable', 'MySchema');
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES (NULL, NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility accepts full name as 1st parm if 2nd parm is null]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MySchema.MyTable',NULL);
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES ('[MySchema]', '[MyTable]');
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE FakeTableTests.[test Private_ResolveFakeTableNamesForBackwardCompatibility accepts parms in wrong order]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MySchema','MyTable');
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES ('[MySchema]', '[MyTable]');
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves UDTd]
AS
BEGIN
  EXEC('CREATE SCHEMA MyTestClass;');
  EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');
  EXEC('CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT);');

  SELECT C.name,C.user_type_id,C.system_type_id 
    INTO #Expected
    FROM sys.columns AS C WHERE C.object_id = OBJECT_ID('MyTestClass.tbl');

  EXEC tSQLt.FakeTable @TableName = 'MyTestClass.tbl';

  SELECT C.name,C.user_type_id,C.system_type_id 
    INTO #Actual
    FROM sys.columns AS C WHERE C.object_id = OBJECT_ID('MyTestClass.tbl');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves UDTd based on char type]
AS
BEGIN
  EXEC('CREATE SCHEMA MyTestClass;');
  EXEC('CREATE TYPE MyTestClass.UDT FROM NVARCHAR(20);');
  EXEC('CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT);');

  SELECT C.name,C.user_type_id,C.system_type_id,C.collation_name 
    INTO #Expected
    FROM sys.columns AS C WHERE C.object_id = OBJECT_ID('MyTestClass.tbl');

  EXEC tSQLt.FakeTable @TableName = 'MyTestClass.tbl';

  SELECT C.name,C.user_type_id,C.system_type_id,C.collation_name 
    INTO #Actual
    FROM sys.columns AS C WHERE C.object_id = OBJECT_ID('MyTestClass.tbl');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROC FakeTableTests.[test can fake local synonym of table]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(c1 INT NULL, c2 BIGINT NULL, c3 VARCHAR(MAX) NULL);
  CREATE SYNONYM FakeTableTests.TempSynonym1 FOR FakeTableTests.TempTable1;
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempSynonym1';

  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'FakeTableTests.TempTable1', @Actual = 'FakeTableTests.TempSynonym1';  
END;
GO

CREATE PROC FakeTableTests.[test raises appropriate error if synonym is not of a table]
AS
BEGIN
  EXEC('CREATE PROCEDURE FakeTableTests.NotATable AS RETURN;');
  CREATE SYNONYM FakeTableTests.TempSynonym1 FOR FakeTableTests.NotATable;
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Cannot fake synonym [FakeTableTests].[TempSynonym1] as it is pointing to [FakeTableTests].[NotATable], which is not a table or view!';
  EXEC tSQLt.FakeTable 'FakeTableTests.TempSynonym1';

END;
GO

CREATE PROC FakeTableTests.[test can fake view]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(c1 INT NULL, c2 BIGINT NULL, c3 VARCHAR(MAX) NULL);
  EXEC('CREATE VIEW FakeTableTests.TempView1 AS SELECT * FROM FakeTableTests.TempTable1;');
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempView1';

  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'FakeTableTests.TempTable1', @Actual = 'FakeTableTests.TempView1';  
END;
GO

CREATE PROC FakeTableTests.[test can fake local synonym of view]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(c1 INT NULL, c2 BIGINT NULL, c3 VARCHAR(MAX) NULL);
  EXEC('CREATE VIEW FakeTableTests.TempView1 AS SELECT * FROM FakeTableTests.TempTable1;');
  CREATE SYNONYM FakeTableTests.TempSynonym1 FOR FakeTableTests.TempView1;
  
  EXEC tSQLt.FakeTable 'FakeTableTests.TempSynonym1';

  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'FakeTableTests.TempTable1', @Actual = 'FakeTableTests.TempSynonym1';  
END;
GO

CREATE PROC FakeTableTests.[test raises error if @TableName is multi-part and @SchemaName is not NULL]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'When @TableName is a multi-part identifier, @SchemaName must be NULL!';
  EXEC tSQLt.FakeTable @TableName = 'aschema.anobject', @SchemaName = 'aschema';

END;
GO

CREATE PROC FakeTableTests.[test raises error if @TableName is quoted multi-part and @SchemaName is not NULL]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'When @TableName is a multi-part identifier, @SchemaName must be NULL!';
  EXEC tSQLt.FakeTable @TableName = '[aschema].[anobject]', @SchemaName = 'aschema';

END;
GO

CREATE PROC FakeTableTests.[test FakeTable works with two parameters, if they are quoted]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT NOT NULL);
  
  EXEC tSQLt.FakeTable '[FakeTableTests]','[TempTable1]';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';

END;
GO

--CREATE PROC FakeTableTests.[test FakeTable works with cross database synonym]
--AS
--BEGIN
--  CREATE TABLE tempdb.dbo.TempTable1(i INT NOT NULL);
--  CREATE SYNONYM FakeTableTests.TempTable1 FOR tempdb.dbo.TempTable1
  
--  EXEC tSQLt.FakeTable '[FakeTableTests]','[TempTable1]';
  
--  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';

--END;
--GO




--ROLLBACK



GO

EXEC tSQLt.NewTestClass 'InfoTests';
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a Version column containing latest build number]
AS
BEGIN
  DECLARE @Version NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @Version = Version
    FROM tSQLt.Info();
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  
  
  IF(@ClrInfo NOT LIKE '%version='+@Version+'%')
  BEGIN
    EXEC tSQLt.Fail 'Expected ''version=',@Version,''' to be part of ''',@ClrInfo,'''.'
  END
END;
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a ClrSigningKey column containing the binary thumbprint of the signing key]
AS
BEGIN
  DECLARE @SigningKeyPattern NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @SigningKeyPattern = '%publickeytoken='+PBH.bare+',%'
    FROM tSQLt.Info() I
   CROSS APPLY tSQLt.Private_Bin2Hex(I.ClrSigningKey) AS PBH;
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  

  EXEC tSQLt.AssertLike @ExpectedPattern = @SigningKeyPattern, @Actual = @ClrInfo, @Message = 'The value returned by tSQLt.Info().ClrSigningKey was not part of the clr_name of the assembly' ;  
END;
GO
CREATE FUNCTION InfoTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition;
GO
CREATE PROCEDURE InfoTests.[test returns SqlVersion and SqlBuild]
AS
BEGIN

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlVersion, I.SqlBuild
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(42.17, 1986.57);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test returns SqlEdition]
AS
BEGIN

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlEdition
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Edition');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;



GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
EXEC tSQLt.NewTestClass 'NameAndIdResolutionTests'
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('[NameAndIdResolutionTests my schema]');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('"NameAndIdResolutionTests my schema"');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO


CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces returns not null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests].[my table]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests"."my table"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if quoted with brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests my schema].[my table]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('NameAndIdResolutionTests my schema.my table');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests my schema"."my table"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('NameAndIdResolutionTests my schema');

	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected SCHEMA_ID of not quoted name to not return null';
END;
GO

-----------------------------

GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('[NameAndIdResolutionTests m.y sche.ma]');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('"NameAndIdResolutionTests m.y sche.ma"');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO


CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces and dots returns not null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests].[m.y tab.le]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces and dots returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests"."m.y tab.le"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('NameAndIdResolutionTests m.y sche.ma');

	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected SCHEMA_ID of not quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if quoted with brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests m.y sche.ma].[m.y tab.le]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('NameAndIdResolutionTests m.y sche.ma.m.y tab.le');
	
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests m.y sche.ma"."m.y tab.le"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
-----------------------------------------------------
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of schema name that does not exist returns null]
AS
BEGIN
	DECLARE @actual INT;
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests my schema');

	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of simple schema name returns id of schema]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = SCHEMA_ID('NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of simple bracket quoted schema name returns id of schema]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = SCHEMA_ID('NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema with brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='[NameAndIdResolutionTests]');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if only unbracketed schema exists]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema when quoted with double quotes]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('"NameAndIdResolutionTests"');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of double quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='"NameAndIdResolutionTests"');
	SELECT @actual = tSQLt.Private_GetSchemaId('"NameAndIdResolutionTests"');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of bracket quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='[NameAndIdResolutionTests]');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of unquoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my.schema];');
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests my.schema');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests my.schema');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO



GO

EXEC tSQLt.NewTestClass 'NewTestClassTests';
GO
CREATE PROC NewTestClassTests.[test NewTestClass creates a new schema]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass')
    BEGIN
        EXEC tSQLt.Fail 'Should have created schema: MyTestClass';
    END;
END;
GO

CREATE PROC NewTestClassTests.[test NewTestClass calls tSQLt.DropClass]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MyTestClass') 
    BEGIN
        EXEC tSQLt.Fail 'Should have called tSQLt.DropClass ''MyTestClass''';
    END
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass should throw an error if the schema exists and is not a test schema]
AS
BEGIN
    DECLARE @Err NVARCHAR(MAX); SET @Err = 'NO ERROR';
    EXEC('CREATE SCHEMA MySchema;');

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
      SET @Err = ERROR_MESSAGE();
    END CATCH
    
    IF @Err NOT LIKE '%Attempted to execute tSQLt.NewTestClass on ''MySchema'' which is an existing schema but not a test class%(Error originated in Private_DisallowOverwritingNonTestSchema)%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
    END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test the NewTestClass-"not a test class" error should be thrown by NewTestClass itself]
AS
BEGIN
    DECLARE @ErrProc NVARCHAR(MAX); SET @ErrProc = 'NO ERROR';
    EXEC('CREATE SCHEMA MySchema;');

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
      SET @ErrProc = ERROR_PROCEDURE();
    END CATCH
    
    EXEC tSQLt.AssertEqualsString 'NewTestClass', @ErrProc;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass should not drop an existing schema if it was not a test class]
AS
BEGIN
    EXEC('CREATE SCHEMA MySchema;');
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
    END CATCH
    
    IF EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MySchema') 
    BEGIN
        EXEC tSQLt.Fail 'Should not have called tSQLt.DropClass ''MySchema''';
    END
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas with the space character]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas with the other special characters]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My!@#$%^&*()Test-+=|\<>,.?/Class';
  
  IF SCHEMA_ID('My!@#$%^&*()Test-+=|\<>,.?/Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My!@#$%^&*()Test-+=|\<>,.?/Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas when the name is already quoted]
AS
BEGIN
  EXEC tSQLt.NewTestClass '[My Test Class]';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test records a new test class in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass 'My Test Class';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test records unquoted name in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass '[My Test Class]';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test inserts name only once in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass works if called on existing test class]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass 'My Test Class';
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass works if called on existing test class quoted]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';
END;
GO



GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
EXEC tSQLt.NewTestClass 'Private_GetFullTypeNameTests';
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return int parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('int'), NULL, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[int]', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARCHAR with length parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varchar'), 8, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varchar](8)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return NVARCHAR with length parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('nvarchar'), 8, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[nvarchar](4)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARCHAR MAX parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varchar'), -1, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varchar](MAX)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARBINARY MAX parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varbinary'), -1, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varbinary](MAX)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return DECIMAL parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('decimal'), NULL, 12, 13, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[decimal](12,13)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return typeName when all parameters are valued]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('int'), 1, 1, 1, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[int]', @Result;
END;
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return typename when xml]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('xml'), -1, 0, 0, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[xml]', @Result;
END;
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should handle all 2005 compatible data types]
AS
BEGIN

  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.bigint]', '[sys].[bigint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.binary]', '[sys].[binary](42)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.bit]', '[sys].[bit]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.char]', '[sys].[char](17)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.datetime]', '[sys].[datetime]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.decimal]', '[sys].[decimal](12,6)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.float]', '[sys].[float]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.image]', '[sys].[image]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.int]', '[sys].[int]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.money]', '[sys].[money]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nchar]', '[sys].[nchar](15)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.ntext]', '[sys].[ntext]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.numeric]', '[sys].[numeric](13,4)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nvarchar]', '[sys].[nvarchar](100)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nvarcharMax]', '[sys].[nvarchar](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.real]', '[sys].[real]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smalldatetime]', '[sys].[smalldatetime]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smallint]', '[sys].[smallint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smallmoney]', '[sys].[smallmoney]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.sql_variant]', '[sys].[sql_variant]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.sysname]', '[sys].[sysname]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.text]', '[sys].[text]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.timestamp]', '[sys].[timestamp]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.tinyint]', '[sys].[tinyint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.uniqueidentifier]', '[sys].[uniqueidentifier]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varbinary]', '[sys].[varbinary](200)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varbinaryMax]', '[sys].[varbinary](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varchar]', '[sys].[varchar](300)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varcharMax]', '[sys].[varchar](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.xml]', '[sys].[xml]');
  
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = STUFF((
                    SELECT ', ' + ColumnName + ' ' + ColumnType
                      FROM dbo.Parms
                       FOR XML PATH(''), TYPE
                   ).value('.','NVARCHAR(MAX)'),1,2,'');
  SET @Cmd = 'CREATE TABLE dbo.tst1(' + @Cmd + ');';

  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;
  EXEC(@Cmd);
  
  SELECT QUOTENAME(c.name) ColumnName, t.TypeName AS ColumnType
    INTO #Actual
    FROM sys.columns c
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, NULL /*Ignore Collations*/) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO


CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should handle CLR datatype]
AS
BEGIN
  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[tSQLt.Private]', '[tSQLt].[Private]');
  
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = STUFF((
                    SELECT ', ' + ColumnName + ' ' + ColumnType
                      FROM dbo.Parms
                       FOR XML PATH(''), TYPE
                   ).value('.','NVARCHAR(MAX)'),1,2,'');
  SET @Cmd = 'CREATE TABLE dbo.tst1(' + @Cmd + ');';

  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;
  EXEC(@Cmd);
  
  SELECT QUOTENAME(c.name) ColumnName, t.TypeName AS ColumnType
    INTO #Actual
    FROM sys.columns c
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, NULL) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO



CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName keeps collation of column]
AS
BEGIN
  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 1]', '[sys].[varchar](MAX) COLLATE Albanian_CS_AS_KS');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 2]', '[sys].[varchar](MAX) COLLATE Latin1_General_CI_AS');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 3]', '[sys].[varchar](MAX) COLLATE SQL_Lithuanian_CP1257_CI_AS');
  
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = STUFF((
                    SELECT ', ' + ColumnName + ' ' + ColumnType
                      FROM dbo.Parms
                       FOR XML PATH(''), TYPE
                   ).value('.','NVARCHAR(MAX)'),1,2,'');
  SET @Cmd = 'CREATE TABLE dbo.tst1(' + @Cmd + ');';

  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;
  EXEC(@Cmd);
  
  SELECT QUOTENAME(c.name) ColumnName, t.TypeName AS ColumnType
    INTO #Actual
    FROM sys.columns c
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, c.collation_name) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO


GO

  EXEC tSQLt.NewTestClass 'Private_NullCellTableTests';
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test table contains a single null cell]
  AS
  BEGIN
     CREATE TABLE Private_NullCellTableTests.Expected (I INT);
     INSERT INTO Private_NullCellTableTests.Expected(I) VALUES (NULL);
     
     EXEC tSQLt.AssertEqualsTable 'Private_NullCellTableTests.Expected', 'tSQLt.Private_NullCellTable';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable]
    @Statement NVARCHAR(MAX)
  AS
  BEGIN
    CREATE TABLE Private_NullCellTableTests.Expected (I INT);
    INSERT INTO Private_NullCellTableTests.Expected(I) VALUES (NULL);

    BEGIN TRY  
      EXEC @Statement;
    END TRY
    BEGIN CATCH
      -- Left intentionally empty
    END CATCH;
  
    EXEC tSQLt.AssertEqualsTable 'Private_NullCellTableTests.Expected', 'tSQLt.Private_NullCellTable';
  
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot insert second NULL row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (NULL);';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot insert a non-NULL row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (5);';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot delete row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'DELETE FROM tSQLt.Private_NullCellTable;';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot update row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'UPDATE tSQLt.Private_NullCellTable SET I = 13;';
  END;
  GO
  


GO

/*--LICENSE--

   Copyright 2012 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

--LICENSE--*/
IF(@@TRANCOUNT>0)ROLLBACK;
GO
EXEC tSQLt.NewTestClass 'Private_RenameObjectToUniqueNameTests';
GO
CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test RenameObjectToUniqueName calls Private_MarkObjectBeforeRename to mark old object]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.aTestObject(i INT);
   
   EXEC tSQLt.SpyProcedure 'tSQLt.Private_MarkObjectBeforeRename';
   
   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'Private_RenameObjectToUniqueNameTests.aTestObject', @NewName = @NewName OUTPUT;
   
   SELECT SchemaName, OriginalName
     INTO #Actual
     FROM tSQLt.Private_MarkObjectBeforeRename_SpyProcedureLog;
     
   SELECT TOP(0) *
     INTO #Expected
     FROM #Actual;

   INSERT INTO #Expected (SchemaName, OriginalName) VALUES ('[Private_RenameObjectToUniqueNameTests]', '[aTestObject]');
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesRenamedObjectLogEntry
 @OriginalName NVARCHAR(MAX)
AS
BEGIN
   EXEC tSQLt.FakeTable 'tSQLt.Private_RenamedObjectLog';
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = @OriginalName;
   
   SELECT ObjectId, OriginalName
     INTO #Actual
     FROM tSQLt.Private_RenamedObjectLog;
     
   SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
   
   DECLARE @ObjectId INT;
   SELECT @ObjectId = OBJECT_ID('Private_RenameObjectToUniqueNameTests.' + @OriginalName);
   
   INSERT INTO #Expected (ObjectId, OriginalName) VALUES (@ObjectId, @OriginalName);
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject marks renamed table with an extended property tSQLt.RenamedObject_OriginalName]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.TheOriginalName(i INT);
   EXEC Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesRenamedObjectLogEntry 'TheOriginalName';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject marks renamed procedure]
AS
BEGIN
   EXEC('CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.TheOriginalName AS RETURN 0;');

   EXEC Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesRenamedObjectLogEntry 'TheOriginalName';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject records rename order]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.TheOriginalTable(i INT);
   EXEC('CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.TheOriginalProc AS RETURN 0;');

   EXEC tSQLt.FakeTable 'tSQLt.Private_RenamedObjectLog', @Identity = 1;
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = 'TheOriginalTable';
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = 'TheOriginalProc';
   
   SELECT Id, OriginalName
     INTO #Actual
     FROM tSQLt.Private_RenamedObjectLog;
     
   SELECT TOP(0) Id + NULL AS Id, OriginalName
    INTO #Expected
    FROM #Actual;
      
   INSERT INTO #Expected (Id, OriginalName) VALUES (1, 'TheOriginalTable');
   INSERT INTO #Expected (Id, OriginalName) VALUES (2, 'TheOriginalProc');
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'Private_ResetNewTestClassListTests';
GO
CREATE PROCEDURE Private_ResetNewTestClassListTests.[test does not fail if Private_NewTestClassList is empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';

  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.Private_ResetNewTestClassList;
END;
GO
CREATE PROCEDURE Private_ResetNewTestClassListTests.[test empties Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc1');
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc2');
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc3');

  EXEC tSQLt.Private_ResetNewTestClassList;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NewTestClassList';
END;
GO


GO

EXEC tSQLt.NewTestClass 'Private_ScriptIndexTests';
GO
CREATE PROCEDURE Private_ScriptIndexTests.[assert index is scripted correctly]
  @setup1 NVARCHAR(MAX) = 'CREATE TABLE Private_ScriptIndexTests.T1(C1 INT, C2 INT, C3 INT, C4 INT);',
  @index_create_cmd NVARCHAR(MAX),
  @setup2 NVARCHAR(MAX) = NULL,
  @object_name NVARCHAR(MAX) = '[Private_ScriptIndexTests].[T1]',
  @index_name NVARCHAR(MAX) = 'Private_ScriptIndexTests.T1 - IDX1'
AS
BEGIN
  EXEC(@setup1);
  EXEC(@index_create_cmd);
  EXEC(@setup2);

  DECLARE @ScriptedCmd NVARCHAR(MAX);
  SELECT @ScriptedCmd = create_cmd
    FROM tSQLt.Private_ScriptIndex(OBJECT_ID(@object_name),(SELECT index_id FROM sys.indexes AS I WHERE I.name = @index_name AND I.object_id = OBJECT_ID(@object_name)));

  EXEC tSQLt.AssertEqualsString @Expected = @index_create_cmd, @Actual = @ScriptedCmd;
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test scripts simple index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test scripts simple multi column index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C2]ASC,[C3]ASC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles ASC and DESC specifiers]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C2]DESC,[C3]DESC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test scripts correct index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @setup1 = 'CREATE TABLE Private_ScriptIndexTests.T1(C1 INT, C2 INT, C3 INT, C4 INT);CREATE CLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC);',
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX2] ON [Private_ScriptIndexTests].[T1]([C2]DESC,[C3]DESC);',
    @setup2 = 'CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX3] ON [Private_ScriptIndexTests].[T1]([C4]ASC);',
    @index_name = 'Private_ScriptIndexTests.T1 - IDX2';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test scripts index on correct table]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @setup1 = 'CREATE TABLE Private_ScriptIndexTests.T2(C2 INT);
               CREATE TABLE Private_ScriptIndexTests.T1(C1 INT);
               CREATE NONCLUSTERED INDEX [IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC);',
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [IDX1] ON [Private_ScriptIndexTests].[T2]([C2]ASC);',
    @object_name = 'Private_ScriptIndexTests.T2',
    @index_name = 'IDX1';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles odd names]
AS
BEGIN
  EXEC('CREATE SCHEMA [some space!];');
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @setup1 = 'CREATE TABLE [some space!].[a table]([a column]INT);',
    @index_create_cmd = 'CREATE NONCLUSTERED INDEX [some space! = a table - a column] ON [some space!].[a table]([a column]ASC);',
    @object_name = '[some space!].[a table]',
    @index_name = 'some space! = a table - a column';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles CLUSTERED indexes]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE CLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C2]DESC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles UNIQUE indexes]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE CLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C2]DESC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test uses key_ordinal for column order]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE CLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C3]ASC,[C1]ASC,[C2]DESC);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles included columns]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C3]DESC)INCLUDE([C4],[C2]);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test scripts all indexes on (@index_id IS NULL)]
AS
BEGIN
  CREATE TABLE Private_ScriptIndexTests.T1(C1 INT, C2 INT, C3 INT, C4 INT);

  CREATE TABLE Private_ScriptIndexTests.Expected(create_cmd NVARCHAR(MAX));
  INSERT INTO Private_ScriptIndexTests.Expected
  VALUES('CREATE CLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C2]DESC);');
  INSERT INTO Private_ScriptIndexTests.Expected
  VALUES('CREATE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX2] ON [Private_ScriptIndexTests].[T1]([C2]ASC,[C3]DESC)INCLUDE([C4]);');
  INSERT INTO Private_ScriptIndexTests.Expected
  VALUES('CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX3] ON [Private_ScriptIndexTests].[T1]([C3]ASC,[C1]DESC);');

  DECLARE @cmd NVARCHAR(MAX);
  SET @cmd = (SELECT create_cmd FROM Private_ScriptIndexTests.Expected FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);

  SELECT create_cmd
    INTO Private_ScriptIndexTests.Actual
    FROM tSQLt.Private_ScriptIndex(OBJECT_ID('[Private_ScriptIndexTests].[T1]'),NULL);

  EXEC tSQLt.AssertEqualsTable 'Private_ScriptIndexTests.Expected','Private_ScriptIndexTests.Actual';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test exposes other important columns]
AS
BEGIN
  CREATE TABLE Private_ScriptIndexTests.T1
  (
    C1 INT,
    C2 INT,
    CONSTRAINT [Private_ScriptIndexTests.T1 - PK] PRIMARY KEY CLUSTERED (C1),
    CONSTRAINT [Private_ScriptIndexTests.T1 - UC1] UNIQUE NONCLUSTERED (C2)
  );
  CREATE INDEX [Private_ScriptIndexTests.T1 - IX1] ON Private_ScriptIndexTests.T1(C2,C1);
  ALTER INDEX [Private_ScriptIndexTests.T1 - IX1] ON Private_ScriptIndexTests.T1 DISABLE;
  
  SELECT PRSN.index_id, PRSN.index_name, PRSN.is_primary_key, PRSN.is_unique, PRSN.is_disabled
    INTO Private_ScriptIndexTests.Actual
    FROM tSQLt.Private_ScriptIndex(OBJECT_ID('Private_ScriptIndexTests.T1'),NULL) AS PRSN;

    SELECT TOP(0) *
    INTO Private_ScriptIndexTests.Expected
    FROM Private_ScriptIndexTests.Actual;
    
    INSERT INTO Private_ScriptIndexTests.Expected
    VALUES(1,'Private_ScriptIndexTests.T1 - PK',1,1,0);
    INSERT INTO Private_ScriptIndexTests.Expected
    VALUES(2,'Private_ScriptIndexTests.T1 - UC1',0,1,0);
    INSERT INTO Private_ScriptIndexTests.Expected
    VALUES(3,'Private_ScriptIndexTests.T1 - IX1',0,0,1);

    EXEC tSQLt.AssertEqualsTable 'Private_ScriptIndexTests.Expected','Private_ScriptIndexTests.Actual';
    
END;
GO


GO

EXEC tSQLt.NewTestClass 'Private_SqlVariantFormatterTests';
GO

CREATE PROC Private_SqlVariantFormatterTests.[test formats INT]
AS
BEGIN
    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @Parameter INT;SET @Parameter = 123;
    SET @Actual =  tSQLt.Private_SqlVariantFormatter(@Parameter);
    EXEC tSQLt.AssertEqualsString '123',@Actual;
END;
GO

CREATE PROC Private_SqlVariantFormatterTests.[test formats other data types]
AS
BEGIN
  CREATE TABLE #Input(
    [BIGINT] BIGINT,
    [BINARY] BINARY(5),
    [CHAR] CHAR(3),
    [DATETIME] DATETIME,
    [DECIMAL] DECIMAL(10,5),
    [FLOAT] FLOAT,
    [INT] INT,
    [MONEY] MONEY,
    [NCHAR] NCHAR(3),
    [NUMERIC] NUMERIC(10,5),
    [NVARCHAR] NVARCHAR(32),
    [REAL] REAL,
    [SMALLDATETIME] SMALLDATETIME,
    [SMALLINT] SMALLINT,
    [SMALLMONEY] SMALLMONEY,
    [TINYINT] TINYINT,
    [UNIQUEIDENTIFIER] UNIQUEIDENTIFIER,
    [VARBINARY] VARBINARY(32),
    [VARCHAR] VARCHAR(32)
  );
  INSERT INTO #Input
  SELECT
    12345 AS [BIGINT],
    0x1F2E3D AS [BINARY],
    'C' AS [CHAR],
    '2013-04-05T06:07:08.987' AS [DATETIME],
    12345.00200 AS [DECIMAL],
    '12345.6789' AS [FLOAT],
    123 AS [INT],
    12345.6789 AS [MONEY],
    N'N' AS [NCHAR],
    12345.00100 AS [NUMERIC],
    N'NVARCHAR' AS [NVARCHAR],
    12345.6789 AS [REAL],
    '2013-04-05T06:07:29' AS [SMALLDATETIME],
    12 AS [SMALLINT],
    12345.6789 AS [SMALLMONEY],
    2 AS [TINYINT],
    'B7F95DDE-1682-4BC6-8511-D6CD8EF947BC' AS [UNIQUEIDENTIFIER],
    0x1234567890ABCDEF AS [VARBINARY],
    'VARCHAR' AS [VARCHAR];

  CREATE TABLE #Actual(
    [BIGINT] NVARCHAR(MAX),
    [BINARY] NVARCHAR(MAX),
    [CHAR] NVARCHAR(MAX),
    [DATETIME] NVARCHAR(MAX),
    [DECIMAL] NVARCHAR(MAX),
    [FLOAT] NVARCHAR(MAX),
    [INT] NVARCHAR(MAX),
    [MONEY] NVARCHAR(MAX),
    [NCHAR] NVARCHAR(MAX),
    [NUMERIC] NVARCHAR(MAX),
    [NVARCHAR] NVARCHAR(MAX),
    [REAL] NVARCHAR(MAX),
    [SMALLDATETIME] NVARCHAR(MAX),
    [SMALLINT] NVARCHAR(MAX),
    [SMALLMONEY] NVARCHAR(MAX),
    [TINYINT] NVARCHAR(MAX),
    [UNIQUEIDENTIFIER] NVARCHAR(MAX),
    [VARBINARY] NVARCHAR(MAX),
    [VARCHAR] NVARCHAR(MAX)
  );
  INSERT INTO #Actual
  SELECT
    tSQLt.Private_SqlVariantFormatter([BIGINT]) AS [BIGINT],
    tSQLt.Private_SqlVariantFormatter([BINARY]) AS [BINARY],
    tSQLt.Private_SqlVariantFormatter([CHAR]) AS [CHAR],
    tSQLt.Private_SqlVariantFormatter([DATETIME]) AS [DATETIME],
    tSQLt.Private_SqlVariantFormatter([DECIMAL]) AS [DECIMAL],
    tSQLt.Private_SqlVariantFormatter([FLOAT]) AS [FLOAT],
    tSQLt.Private_SqlVariantFormatter([INT]) AS [INT],
    tSQLt.Private_SqlVariantFormatter([MONEY]) AS [MONEY],
    tSQLt.Private_SqlVariantFormatter([NCHAR]) AS [NCHAR],
    tSQLt.Private_SqlVariantFormatter([NUMERIC]) AS [NUMERIC],
    tSQLt.Private_SqlVariantFormatter([NVARCHAR]) AS [NVARCHAR],
    tSQLt.Private_SqlVariantFormatter([REAL]) AS [REAL],
    tSQLt.Private_SqlVariantFormatter([SMALLDATETIME]) AS [SMALLDATETIME],
    tSQLt.Private_SqlVariantFormatter([SMALLINT]) AS [SMALLINT],
    tSQLt.Private_SqlVariantFormatter([SMALLMONEY]) AS [SMALLMONEY],
    tSQLt.Private_SqlVariantFormatter([TINYINT]) AS [TINYINT],
    tSQLt.Private_SqlVariantFormatter([UNIQUEIDENTIFIER]) AS [UNIQUEIDENTIFIER],
    tSQLt.Private_SqlVariantFormatter([VARBINARY]) AS [VARBINARY],
    tSQLt.Private_SqlVariantFormatter([VARCHAR]) AS [VARCHAR]
  FROM #Input;

  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected
  SELECT
    '12345' AS [BIGINT],
    '0x1F2E3D0000' AS [BINARY],
    'C' AS [CHAR],
    '2013-04-05T06:07:08.987' AS [DATETIME],
    '12345.00200' AS [DECIMAL],
    '1.234567890000000e+004' AS [FLOAT],
    '123' AS [INT],
    '12345.6789' AS [MONEY],
    'N' AS [NCHAR],
    '12345.00100' AS [NUMERIC],
    'NVARCHAR' AS [NVARCHAR],
    '1.2345679e+004' AS [REAL],
    '2013-04-05T06:07:00' AS [SMALLDATETIME],
    '12' AS [SMALLINT],
    '12345.6789' AS [SMALLMONEY],
    '2' AS [TINYINT],
    'B7F95DDE-1682-4BC6-8511-D6CD8EF947BC' AS [UNIQUEIDENTIFIER],
    '0x1234567890ABCDEF' AS [VARBINARY],
    'VARCHAR' AS [VARCHAR];

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'RemoveObjectIfExistsTests';
GO
CREATE PROCEDURE RemoveObjectIfExistsTests.[test calls tSQLt.RemoveObject with @IfExists = 1]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute = NULL;

  EXEC tSQLt.RemoveObjectIfExists @ObjectName = 'some.name';
  
  SELECT ObjectName,IfExists
    INTO #Actual
    FROM tSQLt.RemoveObject_SpyProcedureLog;
    
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('some.name',1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE RemoveObjectIfExistsTests.[test calls tSQLt.RemoveObject passes @NewName back]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute = 'SET @NewName = ''new.name'';';

  DECLARE @ActualNewName NVARCHAR(MAX); SET @ActualNewName = 'No value was returned!';
  
  EXEC tSQLt.RemoveObjectIfExists @ObjectName = 'some.name',@NewName = @ActualNewName OUT;
  
  EXEC tSQLt.AssertEqualsString @Expected = 'new.name', @Actual = @ActualNewName;
  
END;
GO


GO

/*--LICENSE--

   Copyright 2012 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

--LICENSE--*/
IF(@@TRANCOUNT>0)ROLLBACK;
GO
EXEC tSQLt.NewTestClass 'RemoveObjectTests';
GO
CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a table]
AS
BEGIN
   CREATE TABLE RemoveObjectTests.aTestObject(i INT);

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'table object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a procedure]
AS
BEGIN
   EXEC('CREATE PROCEDURE RemoveObjectTests.aTestObject AS BEGIN RETURN 0; END;');

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'procedure object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a view]
AS
BEGIN
   EXEC ('CREATE VIEW RemoveObjectTests.aTestObject AS SELECT 1 AS X');

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'view object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject raises approporate error if object doesn't exists']
AS
BEGIN
   DECLARE @ErrorMessage NVARCHAR(MAX);
   SET @ErrorMessage = '<NoError>';
   
   BEGIN TRY
     EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aNonExistentTestObject';
   END TRY
   BEGIN CATCH
     SET @ErrorMessage = ERROR_MESSAGE();
   END CATCH
   
   EXEC tSQLt.AssertLike '%RemoveObjectTests.aNonExistentTestObject does not exist!%',@ErrorMessage;  
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject returns silently if object doesn't exists and @IfExists = 1']
AS
BEGIN
   EXEC tSQLt.ExpectNoException;
   
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aNonExistentTestObject', @IfExists = 1;
   
   IF(OBJECT_ID('RemoveObjectTests.aNonExistentTestObject') IS NOT NULL)
   BEGIN
     EXEC tSQLt.Fail 'RemoveObjectTests.aNonExistentTestObject appeared out of thin air!';
   END;
END;
GO

   


GO

EXEC tSQLt.NewTestClass 'RenameClassTests';
GO

CREATE PROCEDURE RenameClassTests.[test empty class can be renamed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT name
    INTO RenameClassTests.Actual
    FROM sys.schemas
   WHERE name LIKE 'RenameClassTests[_]%';

  SELECT TOP(0) *
    INTO RenameClassTests.Expected
    FROM RenameClassTests.Actual;

  INSERT INTO RenameClassTests.Expected (name) VALUES ('RenameClassTests_NewName');

  EXEC tSQLt.AssertEqualsTable 'RenameClassTests.Expected', 'RenameClassTests.Actual';
END;
GO

CREATE PROCEDURE RenameClassTests.[test renamed class with table contains table]
AS
BEGIN
  DECLARE @TableObjectId INT,
          @NewSchemaName NVARCHAR(MAX);

  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  CREATE TABLE RenameClassTests_Class.MyTable (i INT);

  SELECT @TableObjectId = OBJECT_ID('RenameClassTests_Class.MyTable');

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT @NewSchemaName = SCHEMA_NAME(schema_id)
    FROM sys.objects
   WHERE object_id = @TableObjectId;

  EXEC tSQLt.AssertEqualsString 'RenameClassTests_NewName', @NewSchemaName;
END;
GO

CREATE PROCEDURE RenameClassTests.[test doesn't drop any of multiple objects]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  CREATE TABLE RenameClassTests_Class.MyTable (i INT);
  EXEC('CREATE VIEW RenameClassTests_Class.MyView AS SELECT 1 X;');
  EXEC('CREATE PROCEDURE RenameClassTests_Class.MyProc AS RETURN;');

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT name
    INTO RenameClassTests.Actual
    FROM sys.objects
   WHERE schema_id = SCHEMA_ID('RenameClassTests_NewName');

  SELECT TOP(0) *
    INTO RenameClassTests.Expected
    FROM RenameClassTests.Actual;

  INSERT INTO RenameClassTests.Expected (name) 
  SELECT 'MyTable'
  UNION ALL
  SELECT 'MyView'
  UNION ALL
  SELECT 'MyProc'

  EXEC tSQLt.AssertEqualsTable 'RenameClassTests.Expected', 'RenameClassTests.Actual';
END;
GO

CREATE PROCEDURE RenameClassTests.[test renaming a class with strange object names]
AS
BEGIN
  DECLARE @TableObjectId INT,
          @NewSchemaName NVARCHAR(MAX);

  EXEC tSQLt.NewTestClass 'RenameClassTests Class';

  CREATE TABLE [RenameClassTests Class].[strange name] (i INT);

  SELECT @TableObjectId = OBJECT_ID('[RenameClassTests Class].[strange name]');

  EXEC tSQLt.RenameClass 'RenameClassTests Class', 'RenameClassTests NewName';

  SELECT @NewSchemaName = SCHEMA_NAME(schema_id)
    FROM sys.objects
   WHERE object_id = @TableObjectId;

  EXEC tSQLt.AssertEqualsString 'RenameClassTests NewName', @NewSchemaName;
END;
GO

CREATE PROCEDURE RenameClassTests.[test renaming a class with schema names pre-quoted]
AS
BEGIN
  DECLARE @TableObjectId INT,
          @NewSchemaName NVARCHAR(MAX);

  EXEC tSQLt.NewTestClass 'RenameClassTests Class';

  CREATE TABLE [RenameClassTests Class].[strange name] (i INT);

  SELECT @TableObjectId = OBJECT_ID('[RenameClassTests Class].[strange name]');

  EXEC tSQLt.RenameClass '[RenameClassTests Class]', '[RenameClassTests NewName]';

  SELECT @NewSchemaName = SCHEMA_NAME(schema_id)
    FROM sys.objects
   WHERE object_id = @TableObjectId;

  EXEC tSQLt.AssertEqualsString 'RenameClassTests NewName', @NewSchemaName;
END;
GO

CREATE PROCEDURE RenameClassTests.[test transfers tables with foreign keys between them]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  CREATE TABLE RenameClassTests_Class.Table1 (a INT PRIMARY KEY, b INT);
  CREATE TABLE RenameClassTests_Class.Table2 (a INT PRIMARY KEY, b INT);
  CREATE TABLE RenameClassTests_Class.Table3 (a INT PRIMARY KEY, b INT);

  ALTER TABLE RenameClassTests_Class.Table1 ADD CONSTRAINT FK_Table1_Table2 FOREIGN KEY (b) REFERENCES RenameClassTests_Class.Table2(a);
  ALTER TABLE RenameClassTests_Class.Table3 ADD CONSTRAINT FK_Table3_Table2 FOREIGN KEY (b) REFERENCES RenameClassTests_Class.Table2(a);

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT name
    INTO RenameClassTests.Actual
    FROM sys.objects
   WHERE schema_id = SCHEMA_ID('RenameClassTests_NewName')
     AND type = 'U';

  SELECT TOP(0) *
    INTO RenameClassTests.Expected
    FROM RenameClassTests.Actual;

  INSERT INTO RenameClassTests.Expected (name) 
  SELECT 'Table1'
  UNION ALL
  SELECT 'Table2'
  UNION ALL
  SELECT 'Table3'

  EXEC tSQLt.AssertEqualsTable 'RenameClassTests.Expected', 'RenameClassTests.Actual';
END;
GO

CREATE PROCEDURE RenameClassTests.[test transfers XML schema collection]
AS
BEGIN
  DECLARE @XmlCollectionSchemaName NVARCHAR(MAX);

  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  CREATE XML SCHEMA COLLECTION RenameClassTests_Class.XmlSchemaCollection AS N'';

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT @XmlCollectionSchemaName = SCHEMA_NAME(schema_id)
    FROM sys.xml_schema_collections
   WHERE name = 'XmlSchemaCollection';


  EXEC tSQLt.AssertEqualsString 'RenameClassTests_NewName', @XmlCollectionSchemaName;
END;
GO

CREATE PROCEDURE RenameClassTests.[test transfers type]
AS
BEGIN
  DECLARE @TypeSchemaName NVARCHAR(MAX);

  EXEC tSQLt.NewTestClass 'RenameClassTests_Class';

  CREATE TYPE RenameClassTests_Class.MyType FROM INT;

  EXEC tSQLt.RenameClass 'RenameClassTests_Class', 'RenameClassTests_NewName';

  SELECT @TypeSchemaName = SCHEMA_NAME(schema_id)
    FROM sys.types
   WHERE name = 'MyType';

  EXEC tSQLt.AssertEqualsString 'RenameClassTests_NewName', @TypeSchemaName;
END;
GO


GO

EXEC tSQLt.NewTestClass 'ResetTests';
GO
CREATE PROCEDURE ResetTests.[test calls tSQLt.Private_ResetNewTestClassList]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResetNewTestClassList';
  EXEC tSQLt.Reset;

  SELECT _id_
  INTO #Actual
  FROM tSQLt.Private_ResetNewTestClassList_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'Run_Methods_Tests';
GO
CREATE PROC Run_Methods_Tests.[test Run truncates TestResult table]
AS
BEGIN

    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC ('CREATE PROC TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.Run TestCaseA;

    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunTestClass truncates TestResult table]
AS
BEGIN

    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.RunTestClass MyTestClass;
   
    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunTestClass raises error if error in default print mode]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.DefaultResultFormatter';
    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS RETURN 1/0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass MyTestClass;
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    IF(@ErrorRaised = 0)
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not raise an error!';
    END
END;
GO

CREATE PROC Run_Methods_Tests.test_Run_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RAISERROR(''GotHere'',16,10);');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.Test Case A';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Msg 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase, 'GotHere[16,10]{Test Case A,1}' Msg
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run executes all tests in test class when called with class name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    EXEC tSQLt.Run 'innertest';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run executes single test when called with test case name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    EXEC tSQLt.Run 'innertest.testMe';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run re-executes single test when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest.testMe';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run re-executes testClass when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.[test that tSQLt.Run deletes all entries from tSQLt.Run_LastExecution with same SPID]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt', 'Run_LastExecution';
    
    EXEC('EXEC tSQLt.DropClass New;');
    EXEC('CREATE SCHEMA New;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    INSERT tSQLt.Run_LastExecution(SessionId, LoginTime, TestName)
    SELECT @@SPID, '2009-09-09', '[Old1]' UNION ALL
    SELECT @@SPID, '2010-10-10', '[Old2]' UNION ALL
    SELECT @@SPID+10, '2011-11-11', '[Other]';   

    EXEC tSQLt.Run '[New]';
    
    SELECT TestName 
      INTO #Expected
      FROM tSQLt.Run_LastExecution
     WHERE 1=0;
     
    INSERT INTO #Expected(TestName)
    SELECT '[Other]' UNION ALL
    SELECT '[New]';

    SELECT TestName
      INTO #Actual
      FROM tSQLt.Run_LastExecution;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC Run_Methods_Tests.test_RunTestClass_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RETURN 0;');

    EXEC tSQLt.RunTestClass MyTestClass;
    
    SELECT Class, TestCase 
      INTO actual
      FROM tSQLt.TestResult;
      
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test tSQLt.Run executes a test class even if there is a dbo owned object of the same name]
AS
BEGIN
  -- Assemble
  EXEC tSQLt.NewTestClass 'innertest';
  EXEC('CREATE PROC innertest.testMe as RETURN 0;');

  CREATE TABLE dbo.innertest(i INT);

  --Act
  EXEC tSQLt.Run 'innertest';

  --Assert
  SELECT Class, TestCase 
    INTO #Expected
    FROM tSQLt.TestResult
   WHERE 1=0;
   
  INSERT INTO #Expected(Class, TestCase)
  SELECT Class = 'innertest', TestCase = 'testMe';

  SELECT Class, TestCase
    INTO #Actual
    FROM tSQLt.TestResult;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_Run calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  
  EXEC tSQLt.Private_Run 'NoTestSchema.NoTest','SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_OutputTestResults uses the TestResultFormatter parameter]
AS
BEGIN
  EXEC('CREATE PROC Run_Methods_Tests.TemporaryTestResultFormatter AS RAISERROR(''GotHere'',16,10);');
  
  BEGIN TRY
    EXEC tSQLt.Private_OutputTestResults 'Run_Methods_Tests.TemporaryTestResultFormatter';
  END TRY
  BEGIN CATCH
    IF(ERROR_MESSAGE() LIKE '%GotHere%') RETURN 0;
  END CATCH
  EXEC tSQLt.Fail 'Run_Methods_Tests.TemporaryTestResultFormatter did not get called correctly';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunAll calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunTestClass';
  
  EXEC tSQLt.Private_RunAll 'SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithXmlResults calls Run with XmlResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithXmlResults @TestName = 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.XmlResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithXmlResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithXmlResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test NullTestResultFormatter prints no results from the tests]
AS
BEGIN
  EXEC tSQLt.FakeTable 'tSQLt.TestResult';
  
  INSERT INTO tSQLt.TestResult (TestCase) VALUES ('MyTest');
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.NullTestResultFormatter';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test procedure can be injected to display test results]
AS
BEGIN
    EXEC ('CREATE SCHEMA MyFormatterSchema;');
    EXEC ('CREATE TABLE MyFormatterSchema.Log (i INT DEFAULT(1));');
    EXEC ('CREATE PROC MyFormatterSchema.MyFormatter AS INSERT INTO MyFormatterSchema.Log DEFAULT VALUES;');
    EXEC tSQLt.SetTestResultFormatter 'MyFormatterSchema.MyFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.testA AS RETURN 0;');
    
    EXEC tSQLt.Run 'MyTestClass';
    
    CREATE TABLE #Expected (i int DEFAULT(1));
    INSERT INTO #Expected DEFAULT VALUES;
    
    EXEC tSQLt.AssertEqualsTable 'MyFormatterSchema.Log', '#Expected';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates <testsuites/> when no test cases in test suite]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.XmlResultFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    EXEC tSQLt.RunAll;
    
    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = CAST(Message AS NVARCHAR(MAX)) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    EXEC tSQLt.AssertEqualsString '<testsuites/>', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with test element when there is a passing test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  'testA', @Actual;
END;
GO   

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter handles even this:   ,/?'';:[o]]}\|{)(*&^%$#@""]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', ',/?'';:[o]}\|{)(*&^%$#@""', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  ',/?'';:[o]}\|{)(*&^%$#@""', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with test element and failure element when there is a failing test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'This test intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/failure/@message)[1]', 'NVARCHAR(MAX)');
    
    EXEC tSQLt.AssertEqualsString 'This test intentionally fails', @Actual;
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with multiple test elements some with failures]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Success', NULL);
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT TestCase.value('@name','NVARCHAR(MAX)') AS TestCase, TestCase.value('failure[1]/@message','NVARCHAR(MAX)') AS Msg
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TestCase,Msg
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter creates testsuite with multiple test elements some with failures or errors]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT N'MyTestClass' AS Class, 4 tests, 2 failures, 1 errors
    INTO #expected
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter sets correct counts in testsuite attributes]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testE', 'XYZ', 'Failure', 'testE intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT *
    INTO #expected
    FROM (
      SELECT N'MyTestClass1' AS Class, 2 tests, 1 failures, 0 errors
      UNION ALL
      SELECT N'MyTestClass2' AS Class, 3 tests, 2 failures, 1 errors
    ) AS x;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test XmlResultFormatter arranges multiple test cases into testsuites]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT Class,TestCase
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes duration for each test]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:01.000', '2015-07-24T00:00:02.633');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-08-17T20:31:24.758');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:01.666', '2015-07-24T00:00:01.669');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase,
      TestCase.value('@time','NVARCHAR(MAX)') AS Time
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('MyTestClass1', 'testA', '0.136');
    INSERT INTO #Expected
    VALUES('MyTestClass1', 'testB', '1.633');
    INSERT INTO #Expected
    VALUES('MyTestClass2', 'testC', '2147483.646');
    INSERT INTO #Expected
    VALUES('MyTestClass2', 'testD', '0.003');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes start time and total duration per class]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:02.000', '2015-07-24T00:00:02.633');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-07-24T20:31:24.758');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:00.667', '2015-07-24T00:00:01.055');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
   
    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase,
      TestCase.value('@timestamp','NVARCHAR(MAX)') AS Timestamp,
      TestCase.value('@time','NVARCHAR(MAX)') AS Time
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('MyTestClass1', '2015-07-24T00:00:01', '1.633');
    INSERT INTO #Expected
    VALUES('MyTestClass2', '2015-07-24T00:00:00', '73884.090');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test XmlResultFormatter includes other required fields]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (1,'MyTestClass1', 'testA', 'Failure');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (2,'MyTestClass1', 'testB', 'Success');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (3,'MyTestClass2', 'testC', 'Failure');
    INSERT INTO tSQLt.TestResult (Id,Class, TestCase, Result)
    VALUES (4,'MyTestClass2', 'testD', 'Error');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@hostname','NVARCHAR(MAX)') AS Hostname,
      TestCase.value('../@id','NVARCHAR(MAX)') AS id,
      TestCase.value('../@package','NVARCHAR(MAX)') AS package,
      TestCase.value('@name','NVARCHAR(MAX)') AS Testname,
      TestCase.value('failure[1]/@type','NVARCHAR(MAX)') AS FailureType,
      TestCase.value('error[1]/@type','NVARCHAR(MAX)') AS ErrorType
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    DECLARE @ServerName NVARCHAR(MAX); SET @ServerName = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(MAX));
    INSERT INTO #Expected
    VALUES(@ServerName,1,'tSQLt','testA','tSQLt.Fail',NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,1,'tSQLt','testB',NULL,NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,2,'tSQLt','testC','tSQLt.Fail',NULL);
    INSERT INTO #Expected
    VALUES(@ServerName,2,'tSQLt','testD',NULL,'SQL Error');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE Run_Methods_Tests.[test RunWithNullResults calls Run with NullTestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithNullResults 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.NullTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test RunWithNullResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Run';
 
  EXEC tSQLt.RunWithNullResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll executes the SetUp for each test case]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.SetUp AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SetUp AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    EXEC ('CREATE PROC B.testB2 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using RunAll]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using Run with single test]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run 'A.testA';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;

    EXEC tSQLt.Run 'B.testB';

    INSERT INTO #Actual
    SELECT Class, TestCase, Result
      FROM tSQLt.TestResult;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test SetUp can be spelled with any casing when using Run with TestClass]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (i INT);
    INSERT INTO Run_Methods_Tests.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.setup AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SETUP AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run 'A';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;

    EXEC tSQLt.Run 'B';

    INSERT INTO #Actual
    SELECT Class, TestCase, Result
      FROM tSQLt.TestResult;
     
    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;

    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB', Result = 'Success';
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test Run executes the SetUp for each test case in test class]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    CREATE TABLE MyTestClass.SetUpLog (SetupCalled INT);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (SetupCalled INT);
    INSERT INTO Run_Methods_Tests.SetUpLog VALUES (1);
    
    EXEC ('CREATE PROC MyTestClass.SetUp AS INSERT INTO MyTestClass.SetUpLog VALUES (1);');
    EXEC ('CREATE PROC MyTestClass.test1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    EXEC ('CREATE PROC MyTestClass.test2 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunWithNullResults 'MyTestClass';

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'MyTestClass', TestCase = 'test1', Result = 'Success' UNION ALL
    SELECT Class = 'MyTestClass', TestCase = 'test2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test Run executes the SetUp if called for single test]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    CREATE TABLE MyTestClass.SetUpLog (SetupCalled INT);
    
    CREATE TABLE Run_Methods_Tests.SetUpLog (SetupCalled INT);
    INSERT INTO Run_Methods_Tests.SetUpLog VALUES (1);
    
    EXEC ('CREATE PROC MyTestClass.SetUp AS INSERT INTO MyTestClass.SetUpLog VALUES (1);');
    EXEC ('CREATE PROC MyTestClass.test1 AS EXEC tSQLt.AssertEqualsTable ''Run_Methods_Tests.SetUpLog'', ''MyTestClass.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunWithNullResults 'MyTestClass.test1';

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'MyTestClass', TestCase = 'test1', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.test_that_a_failing_SetUp_causes_test_to_be_marked_as_failed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.SetUp AS EXEC tSQLt.Fail ''expected failure'';');
    EXEC('CREATE PROC innertest.test AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass 'innertest';
    END TRY
    BEGIN CATCH
    END CATCH

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'test' AND Result = 'Failure')
    BEGIN
       EXEC tSQLt.Fail 'failing innertest.SetUp did not cause innertest.test to fail.';
   END;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll runs all test classes created with NewTestClass]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA AS RETURN 0;');
    EXEC ('CREATE PROC B.testB AS RETURN 0;');
    EXEC ('CREATE PROC C.testC AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA' UNION ALL
    SELECT Class = 'B', TestCase = 'testB' UNION ALL
    SELECT Class = 'C', TestCase = 'testC';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll runs all test classes created with NewTestClass when there are multiple tests in each class]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA1 AS RETURN 0;');
    EXEC ('CREATE PROC A.testA2 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB1 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB2 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC1 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC2 AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA1' UNION ALL
    SELECT Class = 'A', TestCase = 'testA2' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2' UNION ALL
    SELECT Class = 'C', TestCase = 'testC1' UNION ALL
    SELECT Class = 'C', TestCase = 'testC2';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC Run_Methods_Tests.[test TestResult record with Class and TestCase has Name value of quoted class name and test case name]
AS
BEGIN
    DELETE FROM tSQLt.TestResult;

    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName)
    VALUES ('MyClassName', 'MyTestCaseName', 'XYZ');
    
    SELECT Class, TestCase, Name
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
    
    INSERT INTO #Expected (Class, TestCase, Name)
    VALUES ('MyClassName', 'MyTestCaseName', '[MyClassName].[MyTestCaseName]');
    
    SELECT Class, TestCase, Name
      INTO #Actual
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll produces a test case summary]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';

    EXEC tSQLt.RunAll;

    DECLARE @CallCount INT;
    SELECT @CallCount = COUNT(1) FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    EXEC tSQLt.AssertEquals 1, @CallCount;
END;
GO

CREATE PROC Run_Methods_Tests.[test RunAll clears test results between each execution]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.test1 AS RETURN 0;');

    EXEC tSQLt.RunAll;
    EXEC tSQLt.RunAll;
    
    DECLARE @NumberOfTestResults INT;
    SELECT @NumberOfTestResults = COUNT(*)
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEquals 1, @NumberOfTestResults;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run prints start and stop info when tSQLt.SetVerbose was called]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RAISERROR(''Hello'',0,1)WITH NOWAIT;');

    EXEC tSQLt.SetVerbose;
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = COL.OutputText
      FROM tSQLt.CaptureOutputLog AS COL;
     
    
    DECLARE @Expected NVARCHAR(MAX);SET @Expected =  
'tSQLt.Run ''[innertest].[testMe]''; --Starting
Hello
tSQLt.Run ''[innertest].[testMe]''; --Finished
';
      
    EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run doesn't print start and stop info when tSQLt.SetVerbose 0 was called]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RAISERROR(''Hello'',0,1)WITH NOWAIT;');

    EXEC tSQLt.SetVerbose 0;
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = COL.OutputText
      FROM tSQLt.CaptureOutputLog AS COL;
     
    
    DECLARE @Expected NVARCHAR(MAX);SET @Expected =  
'Hello
';
      
    EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROC Run_Methods_Tests.[test tSQLt.RunC calls tSQLt.Run with everything after ;-- as @TestName]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Run';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_InputBuffer', @CommandToExecute = 'SET @InputBuffer = ''EXEC tSQLt.RunC;--All this gets send to tSQLt.Run as parameter, even chars like '''',-- and []'';';

    EXEC tSQLt.RunC;

    SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('All this gets send to tSQLt.Run as parameter, even chars like '',-- and []');    
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO
CREATE PROC Run_Methods_Tests.[test tSQLt.RunC removes leading and trailing spaces from testname]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Run';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_InputBuffer', @CommandToExecute = 'SET @InputBuffer = ''EXEC tSQLt.RunC;--  XX  '';';

    EXEC tSQLt.RunC;

    SELECT TestName
    INTO #Actual
    FROM tSQLt.Run_SpyProcedureLog;
    
    SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
    INSERT INTO #Expected
    VALUES('XX');    
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures start time]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as WAITFOR DELAY ''00:00:00.111'';');

    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @actual DATETIME;
    DECLARE @after DATETIME;
    DECLARE @before DATETIME;
    
    SET @before = GETDATE();  
    
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';
    
    SET @after = GETDATE();  
    
    SELECT  @actual = TestStartTime
    FROM tSQLt.TestResult AS TR   
    
    DECLARE @msg NVARCHAR(MAX);
    IF(@actual < DATEADD(MILLISECOND,-9,@before) OR @actual > DATEADD(MILLISECOND,-102,@after) OR @actual IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,-9,@before),121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actual,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,-102,@after),121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures finish time]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as WAITFOR DELAY ''00:00:00.111'';');

    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @actual DATETIME;
    DECLARE @after DATETIME;
    DECLARE @before DATETIME;
    
    SET @before = GETDATE();  
    
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';
    
    SET @after = GETDATE();  
    
    SELECT  @actual = TestEndTime
    FROM tSQLt.TestResult AS TR   
    
    DECLARE @msg NVARCHAR(MAX);
    IF(@actual < DATEADD(MILLISECOND,102,@before) OR @actual > DATEADD(MILLISECOND,9,@after) OR @actual IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,102,@before),121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actual,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,9,@after),121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROC Run_Methods_Tests.[test that tSQLt.Private_Run captures finish time for failing test]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as WAITFOR DELAY ''00:00:00.111'';EXEC tSQLt.Fail ''XX'';');

    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';

    DECLARE @actual DATETIME;
    DECLARE @after DATETIME;
    DECLARE @before DATETIME;
    
    SET @before = GETDATE();  
    
    EXEC tSQLt.CaptureOutput @command='EXEC tSQLt.Private_Run ''innertest.testMe'', ''tSQLt.NullTestResultFormatter'';';
    
    SET @after = GETDATE();  
    
    SELECT  @actual = TestEndTime
    FROM tSQLt.TestResult AS TR   
    
    DECLARE @msg NVARCHAR(MAX);
    IF(@actual < DATEADD(MILLISECOND,111,@before) OR @actual > @after OR @actual IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),@before,121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actual,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,-111,@after),121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROC Run_Methods_Tests.[test DefaultResultFormatter outputs test execution duration]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  DECLARE @ttt_object_id INT;SET @ttt_object_id = OBJECT_ID('tSQLt.TableToText');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.TableToText', @CommandToExecute = 'EXEC(''SELECT * INTO Run_Methods_Tests.Actual FROM ''+@TableName);';
                                 
  EXEC('                                                                                    
  INSERT INTO tSQLt.TestResult(Name,Result,TestStartTime,TestEndTime)
  VALUES(''[a test class].[test 1]'',''success'',''2015-07-18T00:00:01.000'',''2015-07-18T00:10:10.555'');
  INSERT INTO tSQLt.TestResult(Name,Result,TestStartTime,TestEndTime)
  VALUES(''[a test class].[test 2]'',''failure'',''2015-07-18T00:00:02.000'',''2015-07-18T00:22:03.444'');
  ');

  EXEC tSQLt.DefaultResultFormatter;

  DROP PROCEDURE tSQLt.TableToText;
  DECLARE @new_ttt_name NVARCHAR(MAX); SET @new_ttt_name = 'tSQLt.'+QUOTENAME(OBJECT_NAME(@ttt_object_id));
  EXEC sys.sp_rename @new_ttt_name,'TableToText','OBJECT';

  SELECT TOP(0) *
  INTO Run_Methods_Tests.Expected
  FROM Run_Methods_Tests.Actual;
  
  INSERT INTO Run_Methods_Tests.Expected
  VALUES(1,'[a test class].[test 1]',' 609556','success');
  INSERT INTO Run_Methods_Tests.Expected
  VALUES(2,'[a test class].[test 2]','1321443','failure');

  EXEC tSQLt.AssertEqualsTable 'Run_Methods_Tests.Expected','Run_Methods_Tests.Actual';
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_GetCursorForRunNew returns all test classes created after(!) tSQLt.Reset was called]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'Test Class A';
    EXEC tSQLt.Reset;
    EXEC tSQLt.NewTestClass 'Test Class B';
    EXEC tSQLt.NewTestClass 'Test Class C';

    DECLARE @TestClassCursor CURSOR;
    EXEC tSQLt.Private_GetCursorForRunNew @TestClassCursor = @TestClassCursor OUT;  

    SELECT Class
    INTO #Actual
      FROM tSQLt.TestResult
     WHERE 1=0;

    DECLARE @TestClass NVARCHAR(MAX);
    WHILE(1=1)
    BEGIN
      FETCH NEXT FROM @TestClassCursor INTO @TestClass;
      IF(@@FETCH_STATUS<>0)BREAK;
      INSERT INTO #Actual VALUES(@TestClass);
    END;
    CLOSE @TestClassCursor;
    DEALLOCATE @TestClassCursor;
    
    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    INSERT INTO #Expected VALUES('Test Class B');    
    INSERT INTO #Expected VALUES('Test Class C');    
     
    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_GetCursorForRunNew skips dropped classes]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.Reset;
    EXEC tSQLt.NewTestClass 'Test Class B';
    EXEC tSQLt.NewTestClass 'Test Class C';
    EXEC tSQLt.DropClass 'Test Class C';

    DECLARE @TestClassCursor CURSOR;
    EXEC tSQLt.Private_GetCursorForRunNew @TestClassCursor = @TestClassCursor OUT;  

    SELECT Class
    INTO #Actual
      FROM tSQLt.TestResult
     WHERE 1=0;

    DECLARE @TestClass NVARCHAR(MAX);
    WHILE(1=1)
    BEGIN
      FETCH NEXT FROM @TestClassCursor INTO @TestClass;
      IF(@@FETCH_STATUS<>0)BREAK;
      INSERT INTO #Actual VALUES(@TestClass);
    END;
    CLOSE @TestClassCursor;
    DEALLOCATE @TestClassCursor;
    
    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    INSERT INTO #Expected VALUES('Test Class B');    
     
    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO
CREATE PROC Run_Methods_Tests.[test Privat_RunNew calls Private_RunCursor with correct cursor]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunCursor';
  
  EXEC tSQLt.Private_RunNew @TestResultFormatter = 'A Test Result Formatter';

  SELECT TestResultFormatter,GetCursorCallback
  INTO #Actual
  FROM tSQLt.Private_RunCursor_SpyProcedureLog;
   
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('A Test Result Formatter','tSQLt.Private_GetCursorForRunNew');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler passes @TestResultFormatter to ssp]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestResultFormatter);');
  
  CREATE TABLE #Actual
  (
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]', @TestResultFormatter = 'a special formatter';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestResultFormatter) VALUES ('a special formatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler defaults @TestResultFormatter to configured Test Result Formatter]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestResultFormatter);');
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
  
  CREATE TABLE #Actual
  (
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestResultFormatter) VALUES ('CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.Private_RunMethodHandler passes @TestName if ssp has that parameter]
AS
BEGIN
  CREATE TABLE #Actual
  (
     TestName NVARCHAR(MAX),
     TestResultFormatter NVARCHAR(MAX)
  );

  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestName NVARCHAR(MAX), @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(@TestName,@TestResultFormatter);');
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
  
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]', @TestName = 'some test';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected(TestName, TestResultFormatter) VALUES ('some test','CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Private_RunMethodHandler calls Private_Init before calling ssp]
AS
BEGIN
  EXEC('CREATE PROCEDURE Run_Methods_Tests.[spy run method] @TestResultFormatter NVARCHAR(MAX) AS INSERT #Actual VALUES(''run method'');');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Init', @CommandToExecute = 'INSERT #Actual VALUES(''Private_Init'');';
  
  CREATE TABLE #Actual
  (
     Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
     Method NVARCHAR(MAX)
  );

  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'Run_Methods_Tests.[spy run method]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES (1,'Private_Init');
  INSERT INTO #Expected VALUES (2,'run method');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunAll calls Private_RunMethodHandler with tSQLt.Private_RunAll]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunMethodHandler';

  EXEC tSQLt.RunAll;

  SELECT RunMethod
  INTO #Actual
  FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES ('tSQLt.Private_RunAll');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test tSQLt.RunNew calls Private_RunMethodHandler with tSQLt.Private_RunNew]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RunMethodHandler';

  EXEC tSQLt.RunNew;

  SELECT RunMethod
  INTO #Actual
  FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    
  INSERT INTO #Expected VALUES ('tSQLt.Private_RunNew');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Run_Methods_Tests.[test Run calls Private_RunMethodHandler correctly]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunMethodHandler';
 
  EXEC tSQLt.Run @TestName = 'some test', @TestResultFormatter = 'some special formatter';
  
  SELECT RunMethod, TestResultFormatter, TestName
    INTO #Actual
    FROM tSQLt.Private_RunMethodHandler_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected (RunMethod, TestResultFormatter, TestName)VALUES('tSQLt.Private_Run', 'some special formatter', 'some test');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'SpyProcedureTests';
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''Original InnerProcedure was executed'';');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure with a parameter]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX) AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with a parameter';

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure with multiple parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log calls]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';

    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log calls with varchar parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(10), @P3 VARCHAR(8000) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';


    IF NOT EXISTS(SELECT 1
                   FROM dbo.InnerProcedure_SpyProcedureLog
                  WHERE P1 = 'with'
                    AND P2 = 'multiple'
                    AND P3 = 'parameters')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow NULL values for sysname parms]
AS
BEGIN
  EXEC('CREATE PROC dbo.InnerProcedure @P1 sysname ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyProcedureLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow NULL values for user defined types created as not nullable]
AS
BEGIN
  EXEC ('CREATE TYPE SpyProcedureTests.MyType FROM INT NOT NULL;');
  
  EXEC('CREATE PROC dbo.InnerProcedure @P1 SpyProcedureTests.MyType ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
  EXEC @InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyProcedureLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log call when output parameters are present]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log values of output parameters if input was provided for them]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    SET @ActualOutputValue = 'HELLO';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'HELLO')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log values if a mix of input an output parameters are provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT, @P2 INT, @P3 BIT OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = 'PARAM1', @P2 = 2, @P3 = 0;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'PARAM1'
                     AND P2 = 2
                     AND P3 = 0)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should not log the default values of parameters if no value is provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) = ''MY DEFAULT'' AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure can be given a command to execute]
AS
BEGIN
    EXEC ('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''InnerProcedure was executed'';');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'RETURN 1';
    
    DECLARE @ReturnVal INT;
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @ReturnVal = @InnerProcedure;
    
    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;
    
    EXEC tSQLt.AssertEquals 1, @ReturnVal;
END;
GO

CREATE PROC SpyProcedureTests.[test command given to SpyProcedure can be used to set output parameters]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'SET @P1 = ''HELLO'';';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    EXEC tSQLt.AssertEqualsString 'HELLO', @ActualOutputValue;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure can have a cursor output parameter]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 CURSOR VARYING OUTPUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @OutputCursor CURSOR;
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @OutputCursor OUTPUT; 
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure raises appropriate error if the procedure does not exist]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      EXEC tSQLt.SpyProcedure 'SpyProcedureTests.DoesNotExist';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %DoesNotExist% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure raises appropriate error if the procedure name given references another type of object]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      CREATE TABLE SpyProcedureTests.dummy (i int);
      EXEC tSQLt.SpyProcedure 'SpyProcedureTests.dummy';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %dummy% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure handles procedure names with spaces]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE PROC SpyProcedureTests.[Spyee Proc] AS RETURN 0;');

    EXEC tSQLt.SpyProcedure 'SpyProcedureTests.[Spyee Proc]';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'SpyProcedureTests.[Spyee Proc]'
    EXEC @InnerProcedure;
    
    SELECT *
      INTO #Actual
      FROM SpyProcedureTests.[Spyee Proc_SpyProcedureLog];
    
    SELECT 1 _id_
      INTO #Expected
     WHERE 0=1;

    INSERT #Expected
    SELECT 1;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure calls tSQLt.Private_RenameObjectToUniqueName on original proc]
AS
BEGIN
    DECLARE @ErrorRaised NVARCHAR(MAX); SET @ErrorRaised = 'No Error Raised';
    
    EXEC('CREATE PROC SpyProcedureTests.SpyeeProc AS RETURN 0;');

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_RenameObjectToUniqueName','RAISERROR(''Intentional Error'', 16, 10)';
    
    BEGIN TRY
        EXEC tSQLt.SpyProcedure  'SpyProcedureTests.SpyeeProc';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = ERROR_MESSAGE();
    END CATCH
    
    EXEC tSQLt.AssertEqualsString 'Intentional Error', @ErrorRaised;
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure works if spyee has 100 parameters with 8000 bytes each]
AS
BEGIN
  IF OBJECT_ID('dbo.InnerProcedure') IS NOT NULL DROP PROCEDURE dbo.InnerProcedure;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.InnerProcedure('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' CHAR(8000)' [text()]
                   FROM tSQLt.F_Num(100)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ExpectedM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ActualM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  SELECT * 
    INTO #Actual1
    FROM #ActualM
   WHERE parameter_id<511;
  SELECT * 
    INTO #Expected1
    FROM #ExpectedM
   WHERE parameter_id<511;
   
  EXEC tSQLt.AssertEqualsTable '#Expected1','#Actual1';

  SELECT * 
    INTO #Actual2
    FROM #ActualM
   WHERE parameter_id>510;
  SELECT * 
    INTO #Expected2
    FROM #ExpectedM
   WHERE parameter_id>510;
   
  EXEC tSQLt.AssertEqualsTable '#Expected2','#Actual2';
END
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates char parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @CHAR1 CHAR(1),
             @CHAR8000 CHAR(8000),
             @VARCHAR1 VARCHAR(1),
             @VARCHAR8000 VARCHAR(8000),
             @VARCHARMAX VARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates binary parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @BINARY1 BINARY(1) =NULL,
             @BINARY4000 BINARY(3000) =NULL,
             @VARBINARY1 VARBINARY(1) =NULL,
             @VARBINARY4000 VARBINARY(3000) =NULL,
             @VARBINARYMAX VARBINARY(MAX) =NULL
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

     EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure creates log which handles binary columns]
AS
BEGIN
    DECLARE @proc NVARCHAR(100); SET @proc = 'dbo.InnerProcedure';
    EXEC('CREATE PROC dbo.InnerProcedure(
             @VARBINARY8000 VARBINARY(8000) =NULL
          )
          AS BEGIN RETURN 0; END');


    EXEC tSQLt.SpyProcedure @proc;
     
    EXEC @proc @VARBINARY8000=0x111122223333444455556666777788889999;

    DECLARE @Actual VARBINARY(8000);
    SELECT @Actual = VARBINARY8000 FROM dbo.InnerProcedure_SpyProcedureLog;
    
    EXEC tSQLt.AssertEquals 0x111122223333444455556666777788889999, @Actual;
END;
GO


CREATE PROC SpyProcedureTests.[test SpyProcedure creates nchar parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @NCHAR1 NCHAR(1),
             @NCHAR4000 NCHAR(4000),
             @NVARCHAR1 NVARCHAR(1),
             @NVARCHAR4000 NVARCHAR(4000),
             @NVARCHARMAX NVARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates other parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @TINYINT TINYINT,
             @SMALLINT SMALLINT,
             @INT INT,
             @BIGINT BIGINT
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure fails with error if spyee has more than 1020 parameters]
AS
BEGIN
  IF OBJECT_ID('dbo.Spyee') IS NOT NULL DROP PROCEDURE dbo.Spyee;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.Spyee('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' INT' [text()]
                   FROM tSQLt.F_Num(1021)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);
  DECLARE @Err VARCHAR(MAX);SET @Err = 'NO ERROR';
  BEGIN TRY
    EXEC tSQLt.SpyProcedure 'dbo.Spyee';
  END TRY
  BEGIN CATCH
    SET @Err = ERROR_MESSAGE();
  END CATCH
  
  IF @Err NOT LIKE '%dbo.Spyee%' AND @Err NOT LIKE '%1020 parameters%'
  BEGIN
      EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
  END;
  
END


GO

EXEC tSQLt.NewTestClass 'StubRecordTests';
GO
CREATE PROC StubRecordTests.[test StubRecord is deployed]
AS
BEGIN
    EXEC tSQLt.AssertObjectExists 'tSQLt.StubRecord';
END;
GO


GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
EXEC tSQLt.NewTestClass 'tSQLt_test';
GO

CREATE PROC tSQLt_test.test_TestCasesAreWrappedInTransactions
AS
BEGIN
    DECLARE @ActualTranCount INT;

    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;

    EXEC ('CREATE PROC TestCaseA AS IF(@@TRANCOUNT < 2) RAISERROR(''TranCountMisMatch:%i'',16,10,@@TRANCOUNT);');

    EXEC tSQLt.Private_RunTest TestCaseA;

    SELECT @ActualTranCount=CAST(SUBSTRING(Msg,19,100) AS INT) FROM tSQLt.TestResult WHERE Msg LIKE 'TranCountMisMatch:%';

    ROLLBACK TRAN @TranName;
    COMMIT;

    IF (@ActualTranCount IS NOT NULL)
    BEGIN
        DECLARE @Message VARCHAR(MAX);
        SET @Message = 'Expected 2 transactions but was '+CAST(@ActualTranCount AS VARCHAR);

        EXEC tSQLt.Fail @Message;
    END;
END;
GO

CREATE PROC tSQLt_test.[test getNewTranName should generate a name]
AS
BEGIN
   DECLARE @Value CHAR(32)

   EXEC tSQLt.GetNewTranName @Value OUT;

   IF @Value IS NULL OR @Value = ''
   BEGIN
      EXEC tSQLt.Fail 'getNewTranName should have returned a name';
   END
END;
GO

CREATE PROC tSQLt_test.test_that_tests_in_testclasses_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'testMe')
    BEGIN
       EXEC tSQLt.Fail 'innertest.testMe did not get executed.';
    END;
END;
GO

CREATE PROC tSQLt_test.test_that_nontests_in_testclasses_do_not_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.do_not_test_me as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'do_not_test_me')
    BEGIN
       EXEC tSQLt.Fail 'innertest.do_not_test_me did get executed.';
    END;
END;
GO


CREATE PROC tSQLt_test.test_Run_handles_uncommitable_transaction
AS
BEGIN
    DECLARE @TranName sysname; 
    SELECT TOP(1) @TranName = TranName FROM tSQLt.TestResult WHERE Class = 'tSQLt_test' AND TestCase = 'test_Run_handles_uncommitable_transaction' ORDER BY Id DESC;
    EXEC ('CREATE PROC testUncommitable AS BEGIN CREATE TABLE t1 (i int); CREATE TABLE t1 (i int); END;');
    BEGIN TRY
        EXEC tSQLt.Run 'testUncommitable';
    END TRY
    BEGIN CATCH
      IF NOT EXISTS(SELECT 1
                      FROM tSQLt.TestResult
                     WHERE TestCase = 'testUncommitable'
                       AND Result = 'Error'
                       AND Msg LIKE '%There is already an object named ''t1'' in the database.[[]%]{testUncommitable,1}%'
                       AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
                   )
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not error correctly';
      END;
      IF(@@TRANCOUNT > 0)
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not rollback the transactions';
      END
      DELETE FROM tSQLt.TestResult
             WHERE TestCase = 'testUncommitable'
               AND Result = 'Error'
               AND Msg LIKE '%There is already an object named ''t1'' in the database.[[]%]{testUncommitable,1}%'
               AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
      BEGIN TRAN
      SAVE TRAN @TranName
    END CATCH
END;
GO


CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles table existing in several schemata]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  EXEC ('CREATE SCHEMA schemaB');
  EXEC ('CREATE SCHEMA schemaC');
  EXEC ('CREATE SCHEMA schemaD');
  EXEC ('CREATE SCHEMA schemaE');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaB.tableA (id INT);
  CREATE TABLE schemaC.tableA (id INT);
  CREATE TABLE schemaD.tableA (id INT);
  CREATE TABLE schemaE.tableA (id INT);
  
  SET @Expected = OBJECT_ID('schemaC.tableA');
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  EXEC tSQLt.FakeTable 'schemaB.tableA';
  EXEC tSQLt.FakeTable 'schemaC.tableA';
  EXEC tSQLt.FakeTable 'schemaD.tableA';
  EXEC tSQLt.FakeTable 'schemaE.tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('schemaC.tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles funky schema name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [s.c.h.e.m.a.A]');
  CREATE TABLE [s.c.h.e.m.a.A].tableA (id INT);
  
  SET @Expected = OBJECT_ID('[s.c.h.e.m.a.A].tableA');
  
  EXEC tSQLt.FakeTable '[s.c.h.e.m.a.A].tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('[s.c.h.e.m.a.A].tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint does not exist on given schema/table]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'constraint_does_not_exist', NULL);
  
  EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint exists on different table in same schema]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaA.tableB (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
 
  SELECT ConstraintObjectId 
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters and different constraint]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT differentConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'differentConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.differentConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Schema, Table, Constraint)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA', 'tableA', 'testConstraint2');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Table, Constraint, Schema)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('tableA', 'testConstraint2', 'schemaA');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record using 3 parameters in different orders]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT parms.id,result.ConstraintObjectId
  INTO #Actual
  FROM ( 
         SELECT 'SCT', 'schemaA', 'testConstraint2', 'tableA' UNION ALL
         SELECT 'TSC', 'tableA', 'schemaA', 'testConstraint2' UNION ALL
         SELECT 'CST', 'testConstraint2', 'schemaA', 'tableA' UNION ALL
         SELECT 'CTS', 'testConstraint2', 'tableA', 'schemaA' UNION ALL
         SELECT 'FNC', 'schemaA.tableA', NULL, 'testConstraint2' UNION ALL
         SELECT 'CFN', 'testConstraint2', 'schemaA.tableA', NULL UNION ALL
         SELECT 'CNF', 'testConstraint2', NULL, 'schemaA.tableA' UNION ALL
         SELECT 'NCF', NULL, 'testConstraint2', 'schemaA.tableA' UNION ALL
         SELECT 'NFC', NULL, 'schemaA.tableA', 'testConstraint2'
       )parms(id,p1,p2,p3)
  CROSS APPLY tSQLt.Private_ResolveApplyConstraintParameters(p1,p2,p3) result;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns two records when names are reused]
-- this test is to document that users with weirdly reused names will have problems...
AS
BEGIN
  EXEC ('CREATE SCHEMA nameA');
  EXEC ('CREATE SCHEMA nameC');
  CREATE TABLE nameA.nameB (id INT CONSTRAINT nameC CHECK (id > 0));
  CREATE TABLE nameC.nameA (id INT CONSTRAINT nameB CHECK (id > 0));

  SELECT *
    INTO #Expected
    FROM (
           SELECT OBJECT_ID('nameA.nameC')
           UNION ALL
           SELECT OBJECT_ID('nameC.nameB')
         )X(ConstraintObjectId);
  
  EXEC tSQLt.FakeTable 'nameA.nameB';
  EXEC tSQLt.FakeTable 'nameC.nameA';
  
  SELECT ConstraintObjectId
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('nameA', 'nameB', 'nameC');

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted table name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [sch emaA]');
  CREATE TABLE [sch emaA].[tab leA] (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable '[sch emaA].[tab leA]';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('[sch emaA].[tab leA]', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('[sch emaA].testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted constraint name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', '[test constraint]', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint returns only one row]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = COUNT(1) FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (1/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (2/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[[test constraint]]]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[[test constraint]]]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (3/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), 'test constraint');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO
----------------------------------------------------

GO
CREATE PROC tSQLt_test.[test f_Num(13) returns 13 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(13);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  INSERT #Expected(no)
  SELECT 1 no UNION ALL
  SELECT 2 no UNION ALL
  SELECT 3 no UNION ALL
  SELECT 4 no UNION ALL
  SELECT 5 no UNION ALL
  SELECT 6 no UNION ALL
  SELECT 7 no UNION ALL
  SELECT 8 no UNION ALL
  SELECT 9 no UNION ALL
  SELECT 10 no UNION ALL
  SELECT 11 no UNION ALL
  SELECT 12 no UNION ALL
  SELECT 13 no;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(0) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(0);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(-11) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(-11);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO

CREATE PROC tSQLt_test.[test that Private_SetFakeViewOn_SingleView allows a non-updatable view to be faked using FakeTable and then inserted into]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');

  EXEC('
      CREATE TABLE NewSchema.A (a1 int, a2 int);
      CREATE TABLE NewSchema.B (a1 int, b1 int, b2 int);
      CREATE TABLE NewSchema.C (b1 int, c1 int, c2 int);
      ');

  EXEC('      
      CREATE VIEW NewSchema.NewView AS
        SELECT A.a1, A.a2, B.b1, B.b2
          FROM NewSchema.A
          JOIN NewSchema.B ON A.a1 < B.a1
          JOIN NewSchema.C ON B.a1 > C.b1;
      ');
      
  -- SetFakeViewOn is executed in a separate batch (typically followed by a GO statement)
  -- than the code of the test case
  EXEC('    
      EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';
      ');
      
  EXEC('
      EXEC tSQLt.FakeTable ''NewSchema'', ''NewView'';
      INSERT INTO NewSchema.NewView (a1, a2, b1, b2) VALUES (1, 2, 3, 4);
      ');

  SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', 'NewSchema.NewView';
  
END
GO

CREATE PROC tSQLt_test.[test that not calling tSQLt.Private_SetFakeViewOff_SingleView before running tests causes an exception and tests not to be run]
AS
BEGIN
  DECLARE @ErrorMsg VARCHAR(MAX); SET @ErrorMsg = '';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  BEGIN TRY
    EXEC tSQLt.Private_RunTest 'TestClass.testExample';
  END TRY
  BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
  END CATCH

  IF @ErrorMsg NOT LIKE '%SetFakeViewOff%'
  BEGIN
    EXEC tSQLt.Fail 'Expected RunTestClass to raise an error because SetFakeViewOff was not executed';
  END;
END
GO

CREATE PROC tSQLt_test.[test that calling tSQLt.Private_SetFakeViewOff_SingleView before running tests allows tests to be run]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  EXEC('EXEC tSQLt.Private_SetFakeViewOff_SingleView @ViewName = ''NewSchema.NewView'';');
  
  BEGIN TRY
    EXEC tSQLt.Run 'TestClass';
  END TRY
  BEGIN CATCH
    DECLARE @Msg VARCHAR(MAX);SET @Msg = ERROR_MESSAGE();
    EXEC tSQLt.Fail 'Expected RunTestClass to not raise an error because Private_SetFakeViewOff_SingleView was executed. Error was:',@Msg;
  END CATCH
END
GO

CREATE PROC tSQLt_test.CreateNonUpdatableView
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_A (a1 int, a2 int);
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_B (a1 int, b1 int, b2 int);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

  SET @Cmd = '
    CREATE VIEW $$SCHEMA_NAME$$.$$VIEW_NAME$$ AS 
      SELECT A.a1, A.a2, B.b1, B.b2
        FROM $$SCHEMA_NAME$$.$$VIEW_NAME$$_A A
        JOIN $$SCHEMA_NAME$$.$$VIEW_NAME$$_B B ON A.a1 = B.a1;';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

END
GO

CREATE PROC tSQLt_test.AssertViewCanBeUpdatedIfFaked
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      EXEC tSQLt.FakeTable ''$$SCHEMA_NAME$$'', ''$$VIEW_NAME$$'';
      INSERT INTO $$SCHEMA_NAME$$.$$VIEW_NAME$$ (a1, a2, b1, b2) VALUES (1, 2, 3, 4);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
  
  SET @Cmd = '
    SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
    EXEC tSQLt.AssertEqualsTable ''#Expected'', ''$$SCHEMA_NAME$$.$$VIEW_NAME$$'';';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOn @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View1';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View2';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View3';
  
  -- Also check that triggers got created. Checking if a view is updatable is
  -- apparently unreliable, since SQL Server could have decided on this run
  -- that these views are updatable at compile time, even though they were not.
  IF (SELECT COUNT(*) FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn') <> 3
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be added.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF EXISTS (SELECT 1 FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName only removes triggers created by framework]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('CREATE TRIGGER NewSchema.View1_SetFakeViewOn ON NewSchema.View1 INSTEAD OF INSERT AS RETURN;');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE [name] = 'View1_SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected View1_SetFakeViewOn trigger not to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that SetFakeViewOn trigger throws meaningful error on execution]
AS
BEGIN
  --This test also tests that tSQLt can handle test that leave the transaction open, but in an uncommitable state.
  DECLARE @Msg VARCHAR(MAX); SET @Msg = 'no error';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  BEGIN TRY
    EXEC('INSERT NewSchema.View1 DEFAULT VALUES;');
  END TRY
  BEGIN CATCH
    SET @Msg = ERROR_MESSAGE();
  END CATCH;
  
  IF(@Msg NOT LIKE '%SetFakeViewOff%')
  BEGIN
    EXEC tSQLt.Fail 'Expected trigger to throw error. Got:',@Msg;
  END;
END
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name that does not exist returns null]
AS
BEGIN
	DECLARE @Actual INT;
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my schema');

	EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple bracket quoted schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema with brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if only unbracketed schema exists]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema when quoted with double quotes]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of double quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='"tSQLt_test"');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of bracket quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of unquoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test my.schema];');
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test my.schema');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my.schema');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does not exist]
AS
BEGIN
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_does_not_exist');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does exist but is not a test class]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test_notATestClass];');
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_notATestClass');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 1 if schema was created with NewTestClass]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_MyTestClass');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass handles bracket quoted test class names]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('[tSQLt_test_MyTestClass]');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns mostly nulls if testname is null]
AS
BEGIN
  SELECT * --forcing this test to test all columns
    INTO #Actual 
    FROM tSQLt.Private_ResolveName(null);

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (NULL, NULL, NULL, NULL, NULL, 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName if testname does not exist returns same info as if testname was null]
AS
BEGIN
  SELECT *
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('NeitherAnObjectNorASchema');

  SELECT *
    INTO #Expected
    FROM tSQLt.Private_ResolveName(null);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

--tSQLt.Private_ResolveTestName(testname)
--returns table
--->bit(class or name),
--  schema_id,
--  object_id (null if testname is a class),
--  quoted schema name,
--  quoted object name (null if testname is a class),
--  quoted full name (quoted schema name if testname is a class)
  
  
--x testname is null
--x testname cannot be resolved
--x testname is a schema name created with NewTestClass
--x testname is a schema name not created with NewTestClass
--x testname is a quoted schema name
--x testname is an object name that is a procedure and a test
--x testname is an object name that is not a procedure
--x testname is an object name that is a procedure but not a test
--x testname is a schema.object name
--x testname is a schema.object name, quoted
--x testname is a [schema.object] name, where dbo.[schema.object] exists and [schema].[object] exists
--testname is a schema name but also an object of the same name exists in dbo
--name is [test schema].[no test]

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns only schema info if testname is a schema created with CREATE SCHEMA]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL, '[InnerSchema]', NULL, '[InnerSchema]', 0, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a test class]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerTest');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase, isSchema)
  VALUES
    (1, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a quoted test class name]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT schemaId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerTest]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId)
  VALUES
    (SCHEMA_ID('InnerTest'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.TestObject');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'), '[InnerSchema]', '[TestObject]', '[InnerSchema].[TestObject]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName interprets object name correctly if schema of same name exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema1');
  EXEC ('CREATE SCHEMA InnerSchema2');
  EXEC ('CREATE TABLE InnerSchema1.InnerSchema2(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema1.InnerSchema2');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema1'), OBJECT_ID('InnerSchema1.InnerSchema2'), '[InnerSchema1]', '[InnerSchema2]', '[InnerSchema1].[InnerSchema2]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified quoted object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for TestProcedure]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[test inside] AS RETURN 0;');

  SELECT isTestClass, isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[test inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase)
  VALUES
    (0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for procedure that is not a test]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[NOtest inside] AS RETURN 0;');

  SELECT isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[NOtest inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestCase)
  VALUES
    (0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema.object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema.TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('dbo'), OBJECT_ID('dbo.[InnerSchema.TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema}.{object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('[InnerSchema].[TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a schema name where an object of same name exists in dbo]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE dbo.InnerSchema(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that is not in sys.objects]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF EXISTS (SELECT 1 FROM sys.objects WHERE NAME = @ObjectName)
  BEGIN
    EXEC tSQLt.Fail 'Created object name already exists in sys.objects, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that has not been previously generated]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF (@ObjectName = tSQLt.Private::CreateUniqueObjectName())
  BEGIN
    EXEC tSQLt.Fail 'Created object name was created twice, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a name which can be used to create a table]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SELECT @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  EXEC ('CREATE TABLE tSQLt_test.' + @ObjectName + '(i INT);');
END
GO

CREATE PROC tSQLt_test.[test Private_Print handles % signs]
AS
BEGIN
  DECLARE @msg NVARCHAR(MAX);
  SET @msg = 'No Message';
  BEGIN TRY
    EXEC tSQLt.Private_Print 'hello % goodbye', 16;
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'hello % goodbye', @msg;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail places parameters in correct order]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail 1, 2, 3, 4, 5, 6, 7, 8, 9, 0;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{1234567890}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail handles NULL parameters]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns no test classes when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns single test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_B');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns other important columns]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name,SchemaId
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name, SchemaId) VALUES ('tSQLt_test_dummy_A',SCHEMA_ID('tSQLt_test_dummy_A'));
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns one test on a test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.testA AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Name) VALUES ('testA');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no test on an empty test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there is only a helper procedure]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.xyz AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests recognizes all TeSt spellings]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.[Test A] AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.[TEST B] AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.[tEsT C] AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (Name) VALUES ('Test A');
  INSERT INTO #Expected (Name) VALUES ('TEST B');
  INSERT INTO #Expected (Name) VALUES ('tEsT C');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns multiple tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test2 AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test3 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test4 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test5 AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test1');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test2');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test3');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test4');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test5');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns relevant ids with tests]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');

  SELECT SchemaId, ObjectId
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (SchemaId, ObjectId) VALUES (SCHEMA_ID('tSQLt_test_dummy_A'), OBJECT_ID('tSQLt_test_dummy_A.test1'));
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes schema tSQLt]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = SCHEMA_ID('tSQLt');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt schema not removed';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes data type tSQLt.Private]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = TYPE_ID('tSQLt.Private');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.Private data type not removed';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes the tSQLt Assembly]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  
  SET @id = (SELECT assembly_id FROM sys.assemblies WHERE name = 'tSQLtCLR');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLtCLR assembly not removed';
  END;
END;
GO

--ROLLBACK
--tSQLt_test


GO

EXEC tSQLt.NewTestClass 'tSQLt_test_AssertResultSetsHaveSameMetaData';
GO
CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for two single bigint column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS BIGINT) A', 
        'SELECT CAST(1 AS BIGINT) A'; 
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for a schema with integer and another with bigint]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData ''SELECT CAST(1 AS INT) A'', ''SELECT CAST(1 AS BIGINT) A'';',
        'Expected tSQLt.Fail to be called when result sets have different meta data';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for identical single column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A', 
        'SELECT CAST(3 AS INT) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1.02 AS DECIMAL(10,2)) A', 
        'SELECT CAST(3.05 AS DECIMAL(10,2)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(15)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(15)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(MAX)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(MAX)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT NULL A', 
        'SELECT NULL A';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for identical multiple column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A, CAST(''ABC'' AS VARCHAR(MAX)) B, CAST(13.9 AS DECIMAL(10,1)) C', 
        'SELECT CAST(3 AS INT) A, CAST(''DEFGH'' AS VARCHAR(MAX)) B, CAST(197.8 AS DECIMAL(10,1)) C';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[xtest AssertResultSetsHaveSameMetaData fails when one result set has no rows for versions before SQL Server 2012]
AS
BEGIN
    -- INTENTIONALLY DISABLED UNTIL WE FIGURE OUT WHY IT SOMETIMES FAILS AND SOMETIMES PASSES
    IF (SELECT CAST(SUBSTRING(product_version, 1, CHARINDEX('.', product_version) - 1) AS INT) FROM sys.dm_os_loaded_modules WHERE name LIKE '%\sqlservr.exe') >= 11
    BEGIN
      EXEC tSQLt.AssertResultSetsHaveSameMetaData
          'SELECT CAST(1 AS INT) A', 
          'SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0';
    END
    ELSE
    BEGIN
      EXEC tSQLt_testutil.assertFailCalled 
          'EXEC tSQLt.AssertResultSetsHaveSameMetaData
              ''SELECT CAST(1 AS INT) A'', 
              ''SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0''',
              'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with result set which returns no metadata';
    END;
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for differing single column result sets]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and BIGINT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1.02 AS DECIMAL(10,2)) A'', 
            ''SELECT CAST(3.05 AS DECIMAL(10,9)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [DECIMAL(10,2) and DECIMAL(10,9)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(15)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(23)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(15) and VARCHAR(23)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(12)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(12) and VARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(MAX)) A'', 
            ''SELECT CAST(''''XYZ'''' AS NVARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(MAX) and NVARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT NULL A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [NULL(INT) and BIGINT]';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for result sets with different number of columns]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT,VARCHAR(MAX) and INT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and INT,VARCHAR(MAX)]';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails if either command produces no result set]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with first command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with second command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with both commands returning no result set';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData throws an exception if a command produces an exception]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT 1/0 AS A', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Divide by zero%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData throws an exception if either command has a syntax error]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT FROM WHERE', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Incorrect syntax near the keyword ''FROM''%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not compare hidden columns]
AS
BEGIN
    EXEC('CREATE VIEW tSQLt_test_AssertResultSetsHaveSameMetaData.TmpView AS SELECT ''X'' Type FROM sys.objects;');

    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT ''X'' AS Type;', 
        'SELECT Type FROM tSQLt_test_AssertResultSetsHaveSameMetaData.TmpView;'; 
END;
GO



GO

EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetFilter';
GO
CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter returns specified result set]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
    
    INSERT INTO #Actual (val)
    EXEC tSQLt.ResultSetFilter 3, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;';
    
    CREATE TABLE #Expected (val INT);
    INSERT INTO #Expected
    SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter returns specified result set with multiple columns]
AS
BEGIN
    CREATE TABLE #Actual (val1 INT, val2 VARCHAR(3));
    
    INSERT INTO #Actual (val1, val2)
    EXEC tSQLt.ResultSetFilter 2, 'SELECT 1 AS val; SELECT 3 AS val1, ''ABC'' AS val2 UNION ALL SELECT 4, ''DEF'' UNION ALL SELECT 5, ''GHI''; SELECT 2 AS val;';
    
    CREATE TABLE #Expected (val1 INT, val2 VARCHAR(3));
    INSERT INTO #Expected
    SELECT 3 AS val1, 'ABC' AS val2 UNION ALL SELECT 4, 'DEF' UNION ALL SELECT 5, 'GHI';
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if specified result set is 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 4, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 3 ResultSets. ResultSet [[]4] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if specified result set is more than 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 9, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val; SELECT 4 AS val; SELECT 5 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 5 ResultSets. ResultSet [[]9] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter retrieves no records and throws no error if 0 is specified]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
    INSERT INTO #Actual
    EXEC tSQLt.ResultSetFilter 0, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    
    CREATE TABLE #Expected (val INT);
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter retrieves no result set if 0 is specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
      EXEC tSQLt.ResultSetFilter 1,'EXEC tSQLt.ResultSetFilter 0, ''SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;'';';  
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 0 ResultSets. ResultSet [[]1] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter handles code not returning a result set]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
      EXEC tSQLt.ResultSetFilter 1,'DECLARE @NoOp INT;';  
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 0 ResultSets. ResultSet [[]1] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws no error if code is not returning a result set and 0 is passed in]
AS
BEGIN
      EXEC tSQLt.ResultSetFilter 0,'DECLARE @NoOp INT;';  
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if result set number NULL specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter NULL, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%ResultSet index begins at 1. ResultSet index [[]Null] is invalid.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO


CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if result set number of less than 0 specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter -1, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%ResultSet index begins at 1. ResultSet index %-1% is invalid.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter can handle each datatype]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''76456376'' AS BIGINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''76456376'''' AS BIGINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x432643'' AS BINARY(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''0x432643'''' AS BINARY(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''1'' AS BIT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''1'''' AS BIT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS CHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS CHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 11:54:12.003'' AS DATETIME) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12/27/2010 11:54:12.003'''' AS DATETIME) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''234.567'' AS DECIMAL(7,4)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''234.567'''' AS DECIMAL(7,4)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS FLOAT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12345.6789'''' AS FLOAT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''XYZ'' AS IMAGE) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''XYZ'''' AS IMAGE) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS INT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13'''' AS INT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12.95'' AS MONEY) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12.95'''' AS MONEY) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NTEXT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NTEXT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''345.67'' AS NUMERIC(7,4)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''345.67'''' AS NUMERIC(7,4)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS REAL) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12345.6789'''' AS REAL) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 09:35'' AS SMALLDATETIME) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12/27/2010 09:35'''' AS SMALLDATETIME) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS SMALLINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13'''' AS SMALLINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13.95'' AS SMALLMONEY) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13.95'''' AS SMALLMONEY) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS SQL_VARIANT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS SQL_VARIANT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS sysname) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS sysname) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS TEXT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS TEXT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x1234'' AS TIMESTAMP) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''0x1234'''' AS TIMESTAMP) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''7'' AS TINYINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''7'''' AS TINYINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'' AS UNIQUEIDENTIFIER) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'''' AS UNIQUEIDENTIFIER) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''<xml>hi</xml>'' AS XML) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''<xml>hi</xml>'''' AS XML) AS val;''';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when underlying table contains primary key]
AS
BEGIN
    CREATE TABLE BaseTable (i INT PRIMARY KEY, v VARCHAR(15));
    INSERT INTO BaseTable (i, v) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v VARCHAR(15));
    INSERT INTO #Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v FROM BaseTable';
    
    CREATE TABLE #Expected (v VARCHAR(15));
    INSERT INTO #Expected (v) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a join on foreign keys is performed]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT PRIMARY KEY, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE BaseTable2 (i2 INT PRIMARY KEY, i1 INT FOREIGN KEY REFERENCES BaseTable1(i1), v2 VARCHAR(15));
    INSERT INTO BaseTable2 (i2, i1, v2) VALUES (1, 1, 'goodbye');
    
    CREATE TABLE #Actual (v1 VARCHAR(15), v2 VARCHAR(15));
    INSERT INTO #Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1, v2 FROM BaseTable1 JOIN BaseTable2 ON BaseTable1.i1 = BaseTable2.i1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15), v2 VARCHAR(15));
    INSERT INTO #Expected (v1, v2) VALUES ('hello', 'goodbye');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a unique column exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT UNIQUE, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v1 VARCHAR(15));
    INSERT INTO #Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15));
    INSERT INTO #Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a check constraint exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT CHECK(i1 = 1), v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v1 VARCHAR(15));
    INSERT INTO #Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15));
    INSERT INTO #Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
EXEC tSQLt.NewTestClass 'tSQLtPrivate_test';
GO

CREATE PROC tSQLtPrivate_test.[test TableToText throws exception if table does not exist]
AS
BEGIN

    DECLARE @err NVARCHAR(MAX); SET @err = 'No Exception occurred!';
    
    BEGIN TRY
        DECLARE @r NVARCHAR(MAX);
        SET @r = tSQLt.Private::TableToString('DoesNotExist', '', NULL);
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Invalid object name ''DoesNotExist''%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText throws exception if tablename is NULL]
AS
BEGIN

    DECLARE @err NVARCHAR(MAX); SET @err = 'No Exception occurred!';
    
    BEGIN TRY
        DECLARE @r NVARCHAR(MAX);
        SET @r = tSQLt.Private::TableToString(NULL, '', NULL);
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Object name cannot be NULL%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one column #table]
AS
BEGIN
    SELECT *
      INTO dbo.DoesExist
      FROM (SELECT 1) AS x(y);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('[dbo].[DoesExist]', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|y|
+-+
|1|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one damn short column]
AS
BEGIN
    SELECT '' [ ]
      INTO #DoesExist
      FROM (SELECT 1) AS x(y);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '| |
+-+
| |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for a weird column name]
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    DECLARE @cmd NVARCHAR(MAX);
    SET @cmd ='
    CREATE TABLE #DoesExist(['+CHAR(8)+''']]] VARCHAR(1));INSERT INTO #DoesExist VALUES('''');
    SET @result = tSQLt.Private::TableToString(''#DoesExist'', '''', NULL);
    ';
    EXEC sp_executesql @cmd,N'@result NVARCHAR(MAX) OUT',@result OUT;
    
    DECLARE @expected NVARCHAR(MAX);
    SET @expected ='|'+CHAR(8)+''']|
+---+
|   |';
    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for column names starting and ending with square brackets]
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    DECLARE @cmd NVARCHAR(MAX);
    SET @cmd ='
    CREATE TABLE #DoesExist([[a]]] VARCHAR(1));INSERT INTO #DoesExist VALUES('''');
    SET @result = tSQLt.Private::TableToString(''#DoesExist'', '''', NULL);
    ';
    EXEC sp_executesql @cmd,N'@result NVARCHAR(MAX) OUT',@result OUT;
    
    DECLARE @expected NVARCHAR(MAX);
    SET @expected ='|[a]|
+---+
|   |';
    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one BIGINT column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T BIGINT
    );
    INSERT INTO #DoesExist (T)
    SELECT ( -(POWER(CAST(-2 AS BIGINT),63)+1)) T
    UNION ALL
    SELECT (POWER(CAST(-2 AS BIGINT),63)) T;
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                   |
+--------------------+
|9223372036854775807 |
|-9223372036854775808|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one TEXT column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T TEXT
    );
    INSERT INTO #DoesExist (T)VALUES('This is my text value');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                    |
+---------------------+
|This is my text value|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one NTEXT column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T NTEXT
    );
    INSERT INTO #DoesExist (T)VALUES(N'This is my text value');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                    |
+---------------------+
|This is my text value|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DOUBLE column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T FLOAT(53)
    );
    INSERT INTO #DoesExist (T)VALUES(1.712345612345610E+308);
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                     |
+----------------------+
|1.712345612345610E+308|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DECIMAL(38, 9) column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DECIMAL(38, 9)
    );
    INSERT INTO #DoesExist (T)VALUES('12345678901234567890123456789.123456789');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                      |
+---------------------------------------+
|12345678901234567890123456789.123456789|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one ROWVERSION column #table]
AS
BEGIN
    DECLARE @rowid ROWVERSION;
    
    CREATE TABLE #DoesExist(
      T ROWVERSION
    );
    INSERT INTO #DoesExist (T) DEFAULT VALUES;
    
    SELECT @rowid = T FROM #DoesExist;
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);

    DECLARE @expected NVARCHAR(MAX);
    SET @expected = '|T                 |
+------------------+
|0x' + REPLACE(CAST(@rowid AS VARBINARY(MAX)), CHAR(0), '00') + '|';

    DECLARE @rowIdBinary VARBINARY(MAX);
    SET @rowIdBinary = CAST(@rowid AS VARBINARY(MAX));
    
    SET @expected = '0x';
    DECLARE @i INT; SET @i = 1;
    DECLARE @si SMALLINT;
    WHILE (@i <= 8)
    BEGIN
        SET @si = CAST(0x00 + CAST(SUBSTRING(@rowIdBinary, @i, 1) AS VARBINARY(2)) AS SMALLINT);
        SET @expected = @expected + CHAR(48 + @si / 16 + CASE WHEN @si / 16 > 9 THEN 7 ELSE 0 END)
        SET @expected = @expected + CHAR(48 + @si % 16 + CASE WHEN @si % 16 > 9 THEN 7 ELSE 0 END)
        SET @i = @i + 1;
    END;
    
    SET @expected = '|T                 |
+------------------+
|' + @expected + '|';
   
    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one UNIQUEID column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T UNIQUEIDENTIFIER
    );
    INSERT INTO #DoesExist (T)VALUES('d7b868c6-c16e-443d-9af9-b23cf83bec0b');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                   |
+------------------------------------+
|d7b868c6-c16e-443d-9af9-b23cf83bec0b|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one XML column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T XML
    );
    INSERT INTO #DoesExist (T)VALUES('<x att="1"><m><l>d1</l><l>d2</l></m></x>');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                       |
+----------------------------------------+
|<x att="1"><m><l>d1</l><l>d2</l></m></x>|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DATETIME column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIME
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T12:34:56.787');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                      |
+-----------------------+
|2001-10-13 12:34:56.787|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one SMALLDATETIME column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T SMALLDATETIME
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T15:34:56.787');

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T               |
+----------------+
|2001-10-13 15:35|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one VARCHAR(MAX)>8000 column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T VARCHAR(MAX)
    );
    INSERT INTO #DoesExist (T)VALUES(REPLICATE(CAST('*' AS VARCHAR(MAX)),8001));
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    DECLARE @expected NVARCHAR(MAX);
    SELECT @expected = '|T'+REPLICATE(' ',154)+'|
+' + REPLICATE('-',155) + '+
|' + REPLICATE('*', 75) + '<...>' + REPLICATE('*', 75) + '|';

    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one IMAGE column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T IMAGE
    );
    INSERT INTO #DoesExist (T)VALUES(CAST(REPLICATE(CAST('*' AS VARCHAR(MAX)),8001) AS VARBINARY(MAX)));
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    DECLARE @expected NVARCHAR(MAX);
    SELECT @expected = '|T'+REPLICATE(' ',154)+'|
+' + REPLICATE('-',155) + '+
|0x2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2<...>A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A|';

    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one SQL_VARIANT column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T SQL_VARIANT
    );
    INSERT INTO #DoesExist (T)VALUES('hello');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    DECLARE @expected NVARCHAR(MAX);
    SELECT @expected = '|T    |
+-----+
|hello|';

    EXEC tSQLt.AssertEqualsString @expected, @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one VARBINARY(MAX) column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T VARBINARY(MAX)
    );
    INSERT INTO #DoesExist (T)VALUES(0xfedcba9876543210);
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                 |
+------------------+
|0xFEDCBA9876543210|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one BINARY(90) column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T VARBINARY(90)
    );
    INSERT INTO #DoesExist (T)VALUES(0x111213141516171819102122232425262728292031323334353637383930414243444546474849405152535455565758595061626364656667686960717273747576777879708182838485868788898091929394959697989990);
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                                                                                                                                          |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
|0x1112131415161718191021222324252627282920313233343536373839304142434445464<...>364656667686960717273747576777879708182838485868788898091929394959697989990|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one CHAR(155) column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T VARCHAR(MAX)
    );
    INSERT INTO #DoesExist (T)VALUES('12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                                                                                                                                          |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
|12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one CHAR(156) column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T VARCHAR(MAX)
    );
    INSERT INTO #DoesExist (T)VALUES('123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                                                                                                                                          |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
|123456789012345678901234567890123456789012345678901234567890123456789012345<...>234567890123456789012345678901234567890123456789012345678901234567890123456|', @result;
END;
GO

-- Maximum display length is greater than maximum column length; however, once we make the display length configurable, we'll need a test LIKE this again
--CREATE PROC tSQLtPrivate_test.[test TableToText works for one long named column #table]
--AS
--BEGIN
--    CREATE TABLE #DoesExist(
--      T12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345 VARCHAR(MAX)
--    );
--    INSERT INTO #DoesExist (T12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345)VALUES('1234567890123456789012345678901234567890123456789012345');
    
--    DECLARE @result NVARCHAR(MAX);
--    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
--    EXEC tSQLt.AssertEqualsString '|T123456789012345678901234<...>1234567890123456789012345|
--+-------------------------------------------------------+
--|1234567890123456789012345678901234567890123456789012345|', @result;
--END;
--GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one column #table with several rows]
AS
BEGIN
    SELECT no
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);

    IF (ISNULL(@result,'') NOT LIKE '|no|
+--+
|[1234] |
|[1234] |
|[1234] |
|[1234] |')
OR (ISNULL(@result,'') NOT LIKE '%1%')
OR (ISNULL(@result,'') NOT LIKE '%2%')
OR (ISNULL(@result,'') NOT LIKE '%3%')
OR (ISNULL(@result,'') NOT LIKE '%4%')
    BEGIN
      EXEC tSQLt.Fail 'TableToString did not return correctly formatted table. It returned: ', @result;
    END
END;
GO


CREATE PROC tSQLtPrivate_test.[test TableToText works if @OrderBy IS NULL]
AS
BEGIN
    SELECT no
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', NULL, NULL);

    IF (ISNULL(@result,'') NOT LIKE '|no|
+--+
|[1234] |
|[1234] |
|[1234] |
|[1234] |')
OR (ISNULL(@result,'') NOT LIKE '%1%')
OR (ISNULL(@result,'') NOT LIKE '%2%')
OR (ISNULL(@result,'') NOT LIKE '%3%')
OR (ISNULL(@result,'') NOT LIKE '%4%')
    BEGIN
      EXEC tSQLt.Fail 'TableToString did not return correctly formatted table. It returned: ', @result;
    END
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText orders by @orderBy]
AS
BEGIN
    SELECT no
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist','10-no+10*(no%2)', NULL);
   
    EXEC tSQLt.AssertEqualsString '|no|
+--+
|4 |
|2 |
|3 |
|1 |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText with no rows]
AS
BEGIN
    SELECT no
      INTO #DoesExist
      FROM tSQLt.F_Num(0);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|no|
+--+', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText with several columns and rows]
AS
BEGIN
    SELECT no, 10-no AS FromTen, NULL AS NullCol
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist','no', NULL);
   
    EXEC tSQLt.AssertEqualsString '|no|FromTen|NullCol|
+--+-------+-------+
|1 |9      |!NULL! |
|2 |8      |!NULL! |
|3 |7      |!NULL! |
|4 |6      |!NULL! |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText with aliased column names]
AS
BEGIN
    SELECT no, 10-no AS FromTen, NULL AS NullCol
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist','no','[Col1],[Col2],[Col3]');
   
    EXEC tSQLt.AssertEqualsString '|Col1|Col2|Col3  |
+----+----+------+
|1   |9   |!NULL!|
|2   |8   |!NULL!|
|3   |7   |!NULL!|
|4   |6   |!NULL!|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test NULL values with short column name]
AS
BEGIN
    SELECT NULL AS n
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist','', NULL);
   
    EXEC tSQLt.AssertEqualsString '|n     |
+------+
|!NULL!|
|!NULL!|
|!NULL!|
|!NULL!|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText with 100 columns]
AS
BEGIN
/*
DECLARE @n INT; SET @n = 100;
DECLARE @cols VARCHAR(MAX);
SET @cols = STUFF((
SELECT ','+CAST(no AS VARCHAR(MAX))+'+no AS C'+RIGHT(CAST(no+100000 AS VARCHAR(MAX)),LEN(CAST(@n AS VARCHAR(MAX))))
FROM tSQLt.F_Num(@n)
FOR XML PATH('')
),1,1,'')
PRINT @cols;
--*/
    SELECT 1+no AS C001,2+no AS C002,3+no AS C003,4+no AS C004,5+no AS C005,6+no AS C006,7+no AS C007,8+no AS C008,9+no AS C009,10+no AS C010,11+no AS C011,12+no AS C012,13+no AS C013,14+no AS C014,15+no AS C015,16+no AS C016,17+no AS C017,18+no AS C018,19+no AS C019,20+no AS C020,21+no AS C021,22+no AS C022,23+no AS C023,24+no AS C024,25+no AS C025,26+no AS C026,27+no AS C027,28+no AS C028,29+no AS C029,30+no AS C030,31+no AS C031,32+no AS C032,33+no AS C033,34+no AS C034,35+no AS C035,36+no AS C036,37+no AS C037,38+no AS C038,39+no AS C039,40+no AS C040,41+no AS C041,42+no AS C042,43+no AS C043,44+no AS C044,45+no AS C045,46+no AS C046,47+no AS C047,48+no AS C048,49+no AS C049,50+no AS C050,51+no AS C051,52+no AS C052,53+no AS C053,54+no AS C054,55+no AS C055,56+no AS C056,57+no AS C057,58+no AS C058,59+no AS C059,60+no AS C060,61+no AS C061,62+no AS C062,63+no AS C063,64+no AS C064,65+no AS C065,66+no AS C066,67+no AS C067,68+no AS C068,69+no AS C069,70+no AS C070,71+no AS C071,72+no AS C072,73+no AS C073,74+no AS C074,75+no AS C075,76+no AS C076,77+no AS C077,78+no AS C078,79+no AS C079,80+no AS C080,81+no AS C081,82+no AS C082,83+no AS C083,84+no AS C084,85+no AS C085,86+no AS C086,87+no AS C087,88+no AS C088,89+no AS C089,90+no AS C090,91+no AS C091,92+no AS C092,93+no AS C093,94+no AS C094,95+no AS C095,96+no AS C096,97+no AS C097,98+no AS C098,99+no AS C099,100+no AS C100
      INTO #DoesExist
      FROM tSQLt.F_Num(4);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist','C001', NULL);
   
    EXEC tSQLt.AssertEqualsString '|C001|C002|C003|C004|C005|C006|C007|C008|C009|C010|C011|C012|C013|C014|C015|C016|C017|C018|C019|C020|C021|C022|C023|C024|C025|C026|C027|C028|C029|C030|C031|C032|C033|C034|C035|C036|C037|C038|C039|C040|C041|C042|C043|C044|C045|C046|C047|C048|C049|C050|C051|C052|C053|C054|C055|C056|C057|C058|C059|C060|C061|C062|C063|C064|C065|C066|C067|C068|C069|C070|C071|C072|C073|C074|C075|C076|C077|C078|C079|C080|C081|C082|C083|C084|C085|C086|C087|C088|C089|C090|C091|C092|C093|C094|C095|C096|C097|C098|C099|C100|
+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
|2   |3   |4   |5   |6   |7   |8   |9   |10  |11  |12  |13  |14  |15  |16  |17  |18  |19  |20  |21  |22  |23  |24  |25  |26  |27  |28  |29  |30  |31  |32  |33  |34  |35  |36  |37  |38  |39  |40  |41  |42  |43  |44  |45  |46  |47  |48  |49  |50  |51  |52  |53  |54  |55  |56  |57  |58  |59  |60  |61  |62  |63  |64  |65  |66  |67  |68  |69  |70  |71  |72  |73  |74  |75  |76  |77  |78  |79  |80  |81  |82  |83  |84  |85  |86  |87  |88  |89  |90  |91  |92  |93  |94  |95  |96  |97  |98  |99  |100 |101 |
|3   |4   |5   |6   |7   |8   |9   |10  |11  |12  |13  |14  |15  |16  |17  |18  |19  |20  |21  |22  |23  |24  |25  |26  |27  |28  |29  |30  |31  |32  |33  |34  |35  |36  |37  |38  |39  |40  |41  |42  |43  |44  |45  |46  |47  |48  |49  |50  |51  |52  |53  |54  |55  |56  |57  |58  |59  |60  |61  |62  |63  |64  |65  |66  |67  |68  |69  |70  |71  |72  |73  |74  |75  |76  |77  |78  |79  |80  |81  |82  |83  |84  |85  |86  |87  |88  |89  |90  |91  |92  |93  |94  |95  |96  |97  |98  |99  |100 |101 |102 |
|4   |5   |6   |7   |8   |9   |10  |11  |12  |13  |14  |15  |16  |17  |18  |19  |20  |21  |22  |23  |24  |25  |26  |27  |28  |29  |30  |31  |32  |33  |34  |35  |36  |37  |38  |39  |40  |41  |42  |43  |44  |45  |46  |47  |48  |49  |50  |51  |52  |53  |54  |55  |56  |57  |58  |59  |60  |61  |62  |63  |64  |65  |66  |67  |68  |69  |70  |71  |72  |73  |74  |75  |76  |77  |78  |79  |80  |81  |82  |83  |84  |85  |86  |87  |88  |89  |90  |91  |92  |93  |94  |95  |96  |97  |98  |99  |100 |101 |102 |103 |
|5   |6   |7   |8   |9   |10  |11  |12  |13  |14  |15  |16  |17  |18  |19  |20  |21  |22  |23  |24  |25  |26  |27  |28  |29  |30  |31  |32  |33  |34  |35  |36  |37  |38  |39  |40  |41  |42  |43  |44  |45  |46  |47  |48  |49  |50  |51  |52  |53  |54  |55  |56  |57  |58  |59  |60  |61  |62  |63  |64  |65  |66  |67  |68  |69  |70  |71  |72  |73  |74  |75  |76  |77  |78  |79  |80  |81  |82  |83  |84  |85  |86  |87  |88  |89  |90  |91  |92  |93  |94  |95  |96  |97  |98  |99  |100 |101 |102 |103 |104 |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText removes quotes from columns in column list]
AS
BEGIN
    SELECT *
      INTO dbo.DoesExist
      FROM (SELECT 1,2) AS x(a,b);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('[dbo].[DoesExist]', '', '[a],[b]');
   
    EXEC tSQLt.AssertEqualsString '|a|b|
+-+-+
|1|2|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText handles brackets in column names in column list]
AS
BEGIN
    SELECT *
      INTO dbo.DoesExist
      FROM (SELECT 1,2) AS x([[a]]],[]]b[]);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('[dbo].[DoesExist]', '', '[[a]]],[]]b[]');
   
    EXEC tSQLt.AssertEqualsString '|[a]|]b[|
+---+---+
|1  |2  |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText handles column name containing ","]
AS
BEGIN
    SELECT *
      INTO dbo.DoesExist
      FROM (SELECT 1,2) AS x(a,[b,c]);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('[dbo].[DoesExist]', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|a|b,c|
+-+---+
|1|2  |', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText handles column containing "," in column list]
AS
BEGIN
    SELECT *
      INTO dbo.DoesExist
      FROM (SELECT 1,2) AS x(a,b);

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('[dbo].[DoesExist]', '', '[a],[b,c]');
   
    EXEC tSQLt.AssertEqualsString '|a|b,c|
+-+---+
|1|2  |', @result;
END;
GO



--EXEC tSQLt.Run 'tSQLtPrivate_test';


GO

/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
EXEC tSQLt.NewTestClass 'tSQLtclr_test';
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput places the console output of a command into the CaptureOutputLog]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput, called with a command that does not print, results in no messages captured]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'DECLARE @i INT;';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput captures output that happens in between resultsets]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'PRINT ''AAAAA'';SELECT 1 a;PRINT ''BBBBB'';SELECT 1 b;PRINT ''CCCCC'';';
  
  DECLARE @OutputText NVARCHAR(MAX);
  SELECT @OutputText = OutputText FROM tSQLt.CaptureOutputLog;
  
  IF(@OutputText NOT LIKE 'AAAAA%BBBBB%CCCCC%')
    EXEC tSQLt.Fail 'Unexpected OutputText Captured! Expected to match ''AAAAA%BBBBB%CCCCC%'', was: ''',@OutputText,'''!';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can be executed twice with the different output]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  EXEC tSQLt.CaptureOutput 'print ''Oh, you got me!!''';
  
  SELECT Id+0 Id,OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(Id,OutputText)VALUES(1,'Catch Me if You Can!' + CHAR(13) + CHAR(10) );
  INSERT INTO #expected(Id,OutputText)VALUES(2,'Oh, you got me!!' + CHAR(13) + CHAR(10) );
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO


CREATE PROC tSQLtclr_test.[test CaptureOutput propogates an error]
AS
BEGIN

  DECLARE @msg NVARCHAR(MAX);
  SELECT @msg = 'No error message';
  
  BEGIN TRY
    EXEC tSQLt.CaptureOutput 'RAISERROR(''hello'', 16, 10);';
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  IF @msg NOT LIKE '%hello%'
    EXEC tSQLt.Fail 'Expected the error message to be propogated up to SQL, but the message was: ', @msg;
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can capture raiserror output with low severity]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'RAISERROR(''Catch Me if You Can!'', 0, 1);';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test SuppressOutput causes no output to be produced]
AS
BEGIN
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.SuppressOutput ''print ''''hello'''';'';';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.Version and tSQLt.Private::info() return the same value]
AS
BEGIN
  DECLARE @tSQLtVersion NVARCHAR(MAX); SET @tSQLtVersion = (SELECT Version FROM tSQLt.Info());
  DECLARE @tSQLtPrivateVersion NVARCHAR(MAX); SET @tSQLtPrivateVersion = (SELECT tSQLt.Private::Info());
  EXEC tSQLt.AssertEqualsString @tSQLtVersion, @tSQLtPrivateVersion;
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.ClrVersion and tSQLt.Private::info() return the same value]
AS
BEGIN
  DECLARE @tSQLtClrVersion NVARCHAR(MAX); SET @tSQLtClrVersion = (SELECT ClrVersion FROM tSQLt.Info());
  DECLARE @tSQLtPrivateVersion NVARCHAR(MAX); SET @tSQLtPrivateVersion = (SELECT tSQLt.Private::Info());
  EXEC tSQLt.AssertEqualsString @tSQLtClrVersion, @tSQLtPrivateVersion;
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.ClrVersion uses tSQLt.Private::info()]
AS
BEGIN
  DECLARE @tSQLtInfoText NVARCHAR(MAX); SET @tSQLtInfoText = OBJECT_DEFINITION(OBJECT_ID('tSQLt.Info'));
  IF( @tSQLtInfoText NOT LIKE '%ClrVersion = (SELECT tSQLt.Private::Info())%')
  BEGIN
    EXEC tSQLt.Fail 'Expected @tSQLtInfoText LIKE ''ClrVersion = (SELECT tSQLt.Private::Info())'' but was:',@tSQLtInfoText;
  END;
END;
GO
--ROLLBACK


GO

