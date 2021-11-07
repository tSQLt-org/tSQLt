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

CREATE PROC ApplyConstraintTests.[test ApplyConstraint can handle data types with length when changing NULLability]
AS
BEGIN
    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (
      Length1 VARCHAR(42) NOT NULL, 
      CONSTRAINT testConstraint PRIMARY KEY (Length1)
    );

    EXEC tSQLt.FakeTable 'schemaA.tableA';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Length1)VALUES(NULL);
    TRUNCATE TABLE schemaA.tableA;

    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Cannot insert the value NULL%Length1%';
    INSERT INTO schemaA.tableA(Length1)VALUES(NULL);
END;
GO

CREATE PROC ApplyConstraintTests.[test ApplyConstraint can handle data types with precision and scale when changing NULLability]
AS
BEGIN
    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (
      Precision_Scale NUMERIC(21,3) NOT NULL, 
      CONSTRAINT testConstraint PRIMARY KEY (Precision_Scale)
    );

    EXEC tSQLt.FakeTable 'schemaA.tableA';

    EXEC tSQLt.ExpectNoException;
    INSERT INTO schemaA.tableA(Precision_Scale)VALUES(NULL);
    TRUNCATE TABLE schemaA.tableA;

    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Cannot insert the value NULL%Precision_Scale%';
    INSERT INTO schemaA.tableA(Precision_Scale)VALUES(NULL);
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
CREATE PROC ApplyConstraintTests.[test ApplyConstraint calls tSQLt.Private_MarktSQLtTempObject on new check constraints]
AS
BEGIN
  CREATE TABLE ApplyConstraintTests.aSimpleTable ( Id INT CONSTRAINT aSimpleTableConstraint CHECK(Id > 0));
  DECLARE @OriginalObjectId INT = OBJECT_ID('ApplyConstraintTests.aSimpleTableConstraint');

  EXEC tSQLt.FakeTable @TableName = 'ApplyConstraintTests.aSimpleTable';

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.ApplyConstraint @TableName = 'ApplyConstraintTests.aSimpleTable', @ConstraintName = 'aSimpleTableConstraint';

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES('[ApplyConstraintTests].[aSimpleTableConstraint]', N'CONSTRAINT', OBJECT_NAME(@OriginalObjectId));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint calls tSQLt.Private_MarktSQLtTempObject on new primary key]
AS
BEGIN
  CREATE TABLE ApplyConstraintTests.aSimpleTable ( Id INT CONSTRAINT aSimpleTableConstraint PRIMARY KEY );
  DECLARE @OriginalObjectId INT = OBJECT_ID('ApplyConstraintTests.aSimpleTableConstraint');

  EXEC tSQLt.FakeTable @TableName = 'ApplyConstraintTests.aSimpleTable';

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.ApplyConstraint @TableName = 'ApplyConstraintTests.aSimpleTable', @ConstraintName = 'aSimpleTableConstraint';

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES('[ApplyConstraintTests].[aSimpleTableConstraint]', N'CONSTRAINT', OBJECT_NAME(@OriginalObjectId));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint calls tSQLt.Private_MarktSQLtTempObject on new unique key]
AS
BEGIN
  CREATE TABLE ApplyConstraintTests.aSimpleTable ( Id INT CONSTRAINT aSimpleTableConstraint UNIQUE );
  DECLARE @OriginalObjectId INT = OBJECT_ID('ApplyConstraintTests.aSimpleTableConstraint');

  EXEC tSQLt.FakeTable @TableName = 'ApplyConstraintTests.aSimpleTable';

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.ApplyConstraint @TableName = 'ApplyConstraintTests.aSimpleTable', @ConstraintName = 'aSimpleTableConstraint';

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES('[ApplyConstraintTests].[aSimpleTableConstraint]', N'CONSTRAINT', OBJECT_NAME(@OriginalObjectId));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROC ApplyConstraintTests.[test ApplyConstraint calls tSQLt.Private_MarktSQLtTempObject on new foreign key]
AS
BEGIN
  CREATE TABLE ApplyConstraintTests.aForeignTable ( Id INT PRIMARY KEY );
  CREATE TABLE ApplyConstraintTests.aSimpleTable ( Id INT, fId INT CONSTRAINT aSimpleTableConstraint FOREIGN KEY REFERENCES ApplyConstraintTests.aForeignTable (Id) );
  DECLARE @OriginalObjectId INT = OBJECT_ID('ApplyConstraintTests.aSimpleTableConstraint');

  EXEC tSQLt.FakeTable @TableName = 'ApplyConstraintTests.aSimpleTable';

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.ApplyConstraint @TableName = 'ApplyConstraintTests.aSimpleTable', @ConstraintName = 'aSimpleTableConstraint';

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES('[ApplyConstraintTests].[aSimpleTableConstraint]', N'CONSTRAINT', OBJECT_NAME(@OriginalObjectId));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
