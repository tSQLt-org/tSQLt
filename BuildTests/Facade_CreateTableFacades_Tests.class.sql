:SETVAR tSQLtFacade tSQLtFacade
GO
EXEC tSQLt.NewTestClass 'Facade_CreateTableFacades_Tests';
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade copies a simple table to the $(tSQLtFacade) database]
AS
BEGIN
  CREATE TABLE dbo.SomeRandomTable(a INT);

  DECLARE @TableObjectId INT = OBJECT_ID('dbo.SomeRandomTable');
  
  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).dbo.SomeRandomTable';
END;
GO

CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade copies another table to the $(tSQLtFacade) database]
AS
BEGIN
  CREATE TABLE dbo.SomeOtherTable(a INT);

  DECLARE @TableObjectId INT = OBJECT_ID('dbo.SomeOtherTable');
  
  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).dbo.SomeOtherTable';
END;
GO

CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade copies table into a schema that does not exist in the $(tSQLtFacade) database]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = 'SomeRandomSchema'+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2);
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE SCHEMA '+@SchemaName+';';
  EXEC(@cmd);

  SET @cmd = 'CREATE TABLE '+@SchemaName+'.SomeTable(a INT);';
  EXEC(@cmd);

  DECLARE @TableObjectId INT = OBJECT_ID(@SchemaName+'.SomeTable');
  
  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;

  DECLARE @RemoteObjectName NVARCHAR(MAX) = '$(tSQLtFacade).'+@SchemaName+'.SomeTable'; 
  EXEC tSQLt.AssertObjectExists @ObjectName = @RemoteObjectName;
END;
GO


CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade copies all columns with their data types]
AS
BEGIN
  CREATE TABLE dbo.SomeOtherTable(a INT IDENTITY(1,1), bb CHAR(1) NULL, ccc DATETIME NOT NULL, dddd NVARCHAR(MAX));

  DECLARE @TableObjectId INT = OBJECT_ID('dbo.SomeOtherTable');
  
  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;

  SELECT 
      C.name,
      C.column_id,
      C.system_type_id,
      C.user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.is_nullable,
      C.is_identity
    INTO #Actual FROM $(tSQLtFacade).sys.columns AS C WHERE C.object_id = OBJECT_ID('$(tSQLtFacade).dbo.SomeOtherTable');

  SELECT 
      C.name,
      C.column_id,
      C.system_type_id,
      C.user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.is_nullable,
      C.is_identity
    INTO #Expected FROM sys.columns AS C WHERE C.object_id = @TableObjectId;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade creates a facade table for a view in the $(tSQLtFacade) database]
AS
BEGIN
  EXEC ('CREATE VIEW dbo.SomeRandomView AS SELECT CAST(1 AS INT) columnNameA;');

  DECLARE @TableObjectId INT = OBJECT_ID('dbo.SomeRandomView');
  
  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;
  
  SELECT 'Is a table.' AS resultColumn INTO #Actual
  FROM $(tSQLtFacade).sys.tables T 
	JOIN $(tSQLtFacade).sys.schemas S ON (T.schema_id = S.schema_id)
  WHERE T.name = 'SomeRandomView' AND S.name = 'dbo';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES ('Is a table.');

  EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';  
END;
GO

CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades doesn't call CreateTableFacade if there are no tables]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateTableFacade_SpyProcedureLog]';
END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades calls CreateTableFacade for single table]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomTable'');');

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT TableObjectId INTO #Actual FROM Facade.[CreateTableFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades calls CreateTableFacade for multiple tables]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''tSQLt''),''cRandomTable'');');

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT TableObjectId INTO #Actual FROM Facade.[CreateTableFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1002),(1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades calls CreateTableFacade only for tables which are not Private]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''PrivateRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''tSQLt''),''PrIVateRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1004,SCHEMA_ID(''tSQLt''),''PRIVATERandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1005,SCHEMA_ID(''tSQLt''),''cRandomTable'');');

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT TableObjectId INTO #Actual FROM Facade.[CreateTableFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1005);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades calls CreateTableFacade only for tables which are in the tSQLt schema]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomTable'');');
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''dbo''),''cRandomTable'');');

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT TableObjectId INTO #Actual FROM Facade.[CreateTableFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1002);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacade works for table names with single quote]
AS
BEGIN
  CREATE TABLE dbo.[SomeR'andomTable] (a INT);

  DECLARE @TableObjectId INT = OBJECT_ID('dbo.[SomeR''andomTable]');

  EXEC Facade.CreateTableFacade @FacadeDbName = '$(tSQLtFacade)', @TableObjectId = @TableObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).dbo.[SomeR''andomTable]';

END;
GO
CREATE PROCEDURE Facade_CreateTableFacades_Tests.[test CreateTableFacades passes @FacadeDbName to CreateTableFacade]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.tables](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc'');');

  EXEC Facade.CreateTableFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT FacadeDbName INTO #Actual FROM Facade.[CreateTableFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(tSQLtFacade)');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
