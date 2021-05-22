:SETVAR tSQLtFacade tSQLtFacade
GO
EXEC tSQLt.NewTestClass 'Facade_CreateFacadeDb_Tests';
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade calls Private_GenerateCreateProcedureSpyStatement]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement';

  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 
  DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.AProc');
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureObjectId = @ProcedureObjectId;

  SELECT 
      ProcedureObjectId,
      OriginalProcedureName
    INTO #Actual FROM tSQLt.Private_GenerateCreateProcedureSpyStatement_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(@ProcedureObjectId,'[dbo].[AProc]');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade passes NULL in @LogTableName & @CommandToExecute for Private_GenerateCreateProcedureSpyStatement]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement';

  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 
  DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.AProc');
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureObjectId = @ProcedureObjectId;

  SELECT 
      LogTableName,
      CommandToExecute
    INTO #Actual FROM tSQLt.Private_GenerateCreateProcedureSpyStatement_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(NULL,NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade executes @CreateProcedureStatement from Private_GenerateCreateProcedureSpyStatement in $(tSQLtFacade)]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 
         @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement', 
         @CommandToExecute='SET @CreateProcedureStatement = ''CREATE PROCEDURE dbo.AProc AS RETURN;'';';

  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureObjectId = NULL;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = definition FROM $(tSQLtFacade).sys.sql_modules WHERE object_id = OBJECT_ID('$(tSQLtFacade).dbo.AProc');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'CREATE PROCEDURE dbo.AProc AS RETURN;', @Actual = @Actual;
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for other schema that does exist in the facade db]
AS
BEGIN
  EXEC('CREATE SCHEMA SomeOtherSchemaForFacadeTests;');
  EXEC $(tSQLtFacade).sys.sp_executesql N'EXEC(''CREATE SCHEMA SomeOtherSchemaForFacadeTests;'');',N'';

  EXEC('CREATE PROC SomeOtherSchemaForFacadeTests.AnotherProc AS RETURN 42;'); 
  DECLARE @ProcedureObjectId INT = OBJECT_ID('SomeOtherSchemaForFacadeTests.AnotherProc');
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureObjectId = @ProcedureObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(tSQLtFacade).SomeOtherSchemaForFacadeTests.AnotherProc';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for other schema that does NOT exist in the facade db]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = 'SomeRandomSchema'+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2);
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE SCHEMA '+@SchemaName+';';
  EXEC(@cmd);

  SET @cmd = 'CREATE PROC '+@SchemaName+'.AnotherProc AS RETURN 42;'; 
  EXEC(@cmd);
  

  DECLARE @ProcedureObjectId INT = OBJECT_ID(@SchemaName+'.AnotherProc');
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureObjectId = @ProcedureObjectId;


  DECLARE @RemoteProcedureName NVARCHAR(MAX) = '$(tSQLtFacade).'+@SchemaName+'.AnotherProc'; 
  EXEC tSQLt.AssertObjectExists @ObjectName = @RemoteProcedureName;
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test Facade.sys.procedures exists]
AS
BEGIN
  SELECT * INTO #Actual FROM Facade.[sys.procedures];
  SELECT * INTO #Expected FROM sys.procedures;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades doesn't call CreateSSPFacade if there's no SSP]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';

  EXEC Facade.CreateSSPFacades;

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateSSPFacade_SpyProcedureLog]';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades calls CreateSSPFacade for single SSP]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc'');');

  EXEC Facade.CreateSSPFacades;

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades calls CreateSSPFacade for multiple SSPs]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc1'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1002,SCHEMA_ID(''tSQLt''),''AProc2'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1003,SCHEMA_ID(''tSQLt''),''AProc3'');');

  EXEC Facade.CreateSSPFacades;

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1002),(1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades calls CreateSSPFacade for schema tSQLt only]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc1'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1002,SCHEMA_ID(''dbo''),''AProc2'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1003,SCHEMA_ID(''tSQLt''),''AProc3'');');

  EXEC Facade.CreateSSPFacades;

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades ignores Private_ SSPs]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc1'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1002,SCHEMA_ID(''tSQLt''),''Private_AProc2'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1003,SCHEMA_ID(''tSQLt''),''PrivateProc3'');');

  EXEC Facade.CreateSSPFacades;

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

/*------------------------
Tests still to write:

-- Functions
-- Tables/views



---------------------------
SELECT * FROM sys.types

drop table dbo.randomtest
SELECT CAST(NULL AS timestamp) [sysname] INTO dbo.randomtest
SELECT * FROM dbo.randomtest

    SELECT O.name
      FROM sys.procedures O
     WHERE 1=1
       AND O.name NOT LIKE 'Private[_]%'
       AND O.schema_id = SCHEMA_ID('tSQLt')
     ORDER BY O.type, O.name

    SELECT O.type,O.type_desc, O.name
      FROM sys.objects O
     WHERE 1=1
       AND O.name NOT LIKE 'Private[_]%'
       AND O.schema_id = SCHEMA_ID('tSQLt')
     ORDER BY O.type, O.name

    SELECT O.type,O.type_desc, COUNT(1) cnt 
      FROM sys.objects O
     WHERE 1=1
       AND O.name NOT LIKE 'Private[_]%'
       AND O.schema_id = SCHEMA_ID('tSQLt')
     GROUP BY O.type, O.type_desc


------------------------*/
