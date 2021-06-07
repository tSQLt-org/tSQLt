---Build-
:SETVAR tSQLtFacade tSQLtFacade
---Build+
GO
EXEC tSQLt.NewTestClass 'Facade_CreateViewFacades_Tests';
GO
CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacade copies a simple view to the $(tSQLtFacade) database]
AS
BEGIN
  EXEC ('CREATE VIEW dbo.SomeRandomView AS SELECT CAST(1 AS INT) a;');
  DECLARE @ViewObjectId INT = OBJECT_ID('dbo.SomeRandomView');
  
  EXEC Facade.CreateViewFacade @FacadeDbName = '$(tSQLtFacade)', @ViewObjectId = @ViewObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).dbo.SomeRandomView';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacade copies another view to the $(tSQLtFacade) database with all columns]
AS
BEGIN
  EXEC ('CREATE VIEW dbo.SomeOtherRandomView AS SELECT CAST(1 AS INT) a, CAST(NULL AS DATETIME) b, CAST(1.1 as NUMERIC(13,10)) c;');
  DECLARE @ViewObjectId INT = OBJECT_ID('dbo.SomeOtherRandomView');
  
  EXEC Facade.CreateViewFacade @FacadeDbName = '$(tSQLtFacade)', @ViewObjectId = @ViewObjectId;

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
    INTO #Actual FROM $(tSQLtFacade).sys.columns AS C WHERE C.object_id = OBJECT_ID('$(tSQLtFacade).dbo.SomeOtherRandomView');

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
    INTO #Expected FROM sys.columns AS C WHERE C.object_id = @ViewObjectId;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacade copies view into a schema that does not exist in the $(tSQLtFacade) database]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = 'SomeRandomSchema'+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2);
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE SCHEMA '+@SchemaName+';';
  EXEC(@cmd);

  SET @cmd = 'CREATE VIEW ' + @SchemaName + '.SomeRandomView AS SELECT CAST(1 AS INT) a;';
  EXEC(@cmd);

  DECLARE @ViewObjectId INT = OBJECT_ID(@SchemaName+'.SomeRandomView');
  
  EXEC Facade.CreateViewFacade @FacadeDbName = '$(tSQLtFacade)', @ViewObjectId = @ViewObjectId;

  DECLARE @RemoteObjectName NVARCHAR(MAX) = '$(tSQLtFacade).'+@SchemaName+'.SomeRandomView'; 
  EXEC tSQLt.AssertObjectExists @ObjectName = @RemoteObjectName;
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacades doesn't call CreateViewFacade if there are no views]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';

  EXEC Facade.CreateViewFacades @FacadeDbName = '$(tSQLtFacade)';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateViewFacade_SpyProcedureLog]';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacades calls CreateViewFacade for single view]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomView'');');

  EXEC Facade.CreateViewFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT FacadeDbName,ViewObjectId INTO #Actual FROM Facade.[CreateViewFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(tSQLtFacade)', 1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacades calls CreateViewFacade for multiple views]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''tSQLt''),''cRandomView'');');

  EXEC Facade.CreateViewFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT FacadeDbName,ViewObjectId INTO #Actual FROM Facade.[CreateViewFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(tSQLtFacade)', 1001),('$(tSQLtFacade)', 1002),('$(tSQLtFacade)', 1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacades calls CreateViewFacade only for views which are not Private]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''PrivateRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''tSQLt''),''PrIVateRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1004,SCHEMA_ID(''tSQLt''),''PRIVATERandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1005,SCHEMA_ID(''tSQLt''),''cRandomView'');');

  EXEC Facade.CreateViewFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT ViewObjectId INTO #Actual FROM Facade.[CreateViewFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1005);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacades calls CreateViewFacade only for views which are in the tSQLt schema]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.tables]';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.views]';
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomView'');');
  EXEC('INSERT INTO Facade.[sys.views](object_id,schema_id,name) VALUES (1003,SCHEMA_ID(''dbo''),''cRandomView'');');

  EXEC Facade.CreateViewFacades @FacadeDbName = '$(tSQLtFacade)';

  SELECT ViewObjectId INTO #Actual FROM Facade.[CreateViewFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1002);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateViewFacades_Tests.[test CreateViewFacade works for view names with single quote]
AS
BEGIN
  EXEC ('CREATE VIEW dbo.[SomeRa''ndomView] AS SELECT CAST(1 AS INT) a;');
  DECLARE @ViewObjectId INT = OBJECT_ID('dbo.[SomeRa''ndomView]');

  EXEC Facade.CreateViewFacade @FacadeDbName = '$(tSQLtFacade)', @ViewObjectId = @ViewObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).dbo.[SomeRa''ndomView]';
END;
GO
