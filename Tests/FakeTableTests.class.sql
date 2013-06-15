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
      EXEC tSQLt.FakeTable 'schemaA', 'tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaA.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
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
      EXEC tSQLt.FakeTable 'schemaB', 'tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
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
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''(null)''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
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
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
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
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC FakeTableTests.[test a faked table has no check constraints]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT CHECK(i > 5));
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC FakeTableTests.[test a faked table has no foreign keys]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable0(i INT PRIMARY KEY);
  CREATE TABLE FakeTableTests.TempTable1(i INT REFERENCES FakeTableTests.TempTable0(i));
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any defaults removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT DEFAULT(77));
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
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
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
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
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
  EXEC FakeTableTests.AssertTableIsNewObjectThatHasNoConstraints 'FakeTableTests.TempTable1';
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
  INSERT INTO FakeTableTests.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC FakeTableTests.[test FakeTable: a faked table has any not null constraints removed]
AS
BEGIN
  CREATE TABLE FakeTableTests.TempTable1(i INT NOT NULL);
  
  EXEC tSQLt.FakeTable 'FakeTableTests','TempTable1';
  
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
    EXEC tSQLt.FakeTable 'FakeTableTests', 'tst1';
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
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.FakeTable ''FakeTableTests'', ''tst''';

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
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;

  CREATE TABLE tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'tst1';
  
  IF EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has identity column!';
  END
END;
GO

CREATE PROC FakeTableTests.[test FakeTable doesn't preserve identity if @identity parameter is 0]
AS
BEGIN
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;

  CREATE TABLE tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'tst1',@Identity=0;
  
  IF EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has identity column!';
  END
END;
GO

CREATE PROC FakeTableTests.[test FakeTable preserves identity if @identity parameter is 1]
AS
BEGIN
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;

  CREATE TABLE tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable 'tst1',@Identity=1;
  
  IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has no identity column!';
  END
END;
GO


CREATE PROC FakeTableTests.[test FakeTable works with more than one column]
AS
BEGIN
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;

  CREATE TABLE dbo.tst1(i1 INT,i2 INT,i3 INT,i4 INT,i5 INT,i6 INT,i7 INT,i8 INT);

  SELECT column_id,name
    INTO #Expected
    FROM sys.columns
   WHERE object_id = OBJECT_ID('dbo.tst1')
  
  EXEC tSQLt.FakeTable 'tst1';

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
  
  EXEC tSQLt.FakeTable 'tst1',@Identity = 0;

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
  
  EXEC tSQLt.FakeTable 'tst1',@Identity = 1;

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
  
  EXEC tSQLt.FakeTable 'tst1',@Identity = 1;

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
  
  EXEC tSQLt.FakeTable 'tst1',@Identity = 1;

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
  
  EXEC FakeTableTests.AssertTableAfterCommandHasNoDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''tst1''';
END;
GO

CREATE PROC FakeTableTests.[test FakeTable does not preserve defaults if @Defaults = 0]
AS
BEGIN
  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;

  CREATE TABLE dbo.tst1(x INT DEFAULT(5));

  EXEC FakeTableTests.AssertTableAfterCommandHasNoDefaults 'dbo.tst1', 'EXEC tSQLt.FakeTable ''tst1'', @Defaults = 0;';
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
  
  EXEC tSQLt.FakeTable 'tst1',@Identity = 1;

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

--ROLLBACK

