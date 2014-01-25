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