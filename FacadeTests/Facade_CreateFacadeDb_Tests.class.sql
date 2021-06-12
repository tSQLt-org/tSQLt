:SETVAR FacadeTargetDb tSQLtFacade
---Build+
GO
EXEC tSQLt.NewTestClass 'Facade_CreateFacadeDb_Tests';
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade calls Private_GenerateCreateProcedureSpyStatement]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement';

  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 
  DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.AProc');
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;

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
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;

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
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade executes @CreateProcedureStatement from Private_GenerateCreateProcedureSpyStatement in facade db]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 
         @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement', 
         @CommandToExecute='SET @CreateProcedureStatement = ''CREATE PROCEDURE dbo.AProc AS RETURN;'';';

  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = NULL;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = definition FROM $(FacadeTargetDb).sys.sql_modules WHERE object_id = OBJECT_ID('$(FacadeTargetDb).dbo.AProc');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'CREATE PROCEDURE dbo.AProc AS RETURN;', @Actual = @Actual;
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for other schema that does exist in the facade db]
AS
BEGIN
  EXEC('CREATE SCHEMA SomeOtherSchemaForFacadeTests;');
  EXEC $(FacadeTargetDb).sys.sp_executesql N'EXEC(''CREATE SCHEMA SomeOtherSchemaForFacadeTests;'');',N'';

  EXEC('CREATE PROC SomeOtherSchemaForFacadeTests.AnotherProc AS RETURN 42;'); 
  DECLARE @ProcedureObjectId INT = OBJECT_ID('SomeOtherSchemaForFacadeTests.AnotherProc');
  
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;

  EXEC tSQLt.AssertObjectExists @ObjectName = '$(FacadeTargetDb).SomeOtherSchemaForFacadeTests.AnotherProc';
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
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;


  DECLARE @RemoteProcedureName NVARCHAR(MAX) = '$(FacadeTargetDb).'+@SchemaName+'.AnotherProc'; 
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

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateSSPFacade_SpyProcedureLog]';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades calls CreateSSPFacade for single SSP]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc'');');

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

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

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

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

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001),(1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades ignores Private SSPs]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc1'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1002,SCHEMA_ID(''tSQLt''),''Private_AProc2'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1003,SCHEMA_ID(''tSQLt''),''PrivateProc3'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1004,SCHEMA_ID(''tSQLt''),''PrIVateProc3'');');
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1005,SCHEMA_ID(''tSQLt''),''PRIVATEProc3'');');

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT ProcedureObjectId INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacade executes the statement returned from tSQLt.Private_CreateFakeFunctionStatement in the facade db]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = N'tSQLt.Private_CreateFakeFunctionStatement',
                          @FakeDataSource = N'SELECT ''CREATE FUNCTION dbo.aRandomFunction () RETURNS INT AS BEGIN RETURN 1; END;'' CreateStatement';

  EXEC Facade.CreateSFNFacade @FacadeDbName = '$(FacadeTargetDb)', @FunctionObjectId = NULL;

  SELECT 'Is a function.' AS resultColumn INTO #Actual
    FROM $(FacadeTargetDb).sys.objects O 
	JOIN $(FacadeTargetDb).sys.schemas S ON (O.schema_id = S.schema_id)
   WHERE O.name = 'aRandomFunction' 
	 AND S.name = 'dbo'
	 AND O.type = 'FN';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES ('Is a function.');

  EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';  
END;
GO
CREATE FUNCTION Facade_CreateFacadeDb_Tests.[THROW @FunctionObjectId]
(
  @FunctionObjectId INT,
  @ReturnValue NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN SELECT 'RAISERROR (''@FunctionObjectId=%i'',16,1,' + CAST(@FunctionObjectId AS NVARCHAR(MAX)) + ');' CreateStatement;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacade passes the correct object id to tSQLt.Private_CreateFakeFunctionStatement]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = N'tSQLt.Private_CreateFakeFunctionStatement',
                          @FakeFunctionName = 'Facade_CreateFacadeDb_Tests.[THROW @FunctionObjectId]';

  EXEC tSQLt.ExpectException @ExpectedMessage = N'@FunctionObjectId=4217';
  
  EXEC Facade.CreateSFNFacade @FacadeDbName = '$(FacadeTargetDb)', @FunctionObjectId = 4217;

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacade creates schema if it doesn't already exist]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = 'SomeRandomSchema'+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2);
  DECLARE @FakeDataSourceStatement NVARCHAR(MAX) = N'SELECT ''CREATE FUNCTION ' + @SchemaName + '.aRandomFunction () RETURNS INT AS BEGIN RETURN 1; END;'' CreateStatement';
  DECLARE @cmd NVARCHAR(MAX) = 'CREATE SCHEMA ' + @SchemaName; 
  DECLARE @FunctionObjectId INT;

  EXEC (@cmd); 
  EXEC ('CREATE FUNCTION ' + @SchemaName + '.aRandomFunction () RETURNS INT AS BEGIN RETURN 1; END;');
  SET @FunctionObjectId = OBJECT_ID(@SchemaName + '.aRandomFunction');

  EXEC tSQLt.FakeFunction @FunctionName = N'tSQLt.Private_CreateFakeFunctionStatement',
                          @FakeDataSource = @FakeDataSourceStatement;

  EXEC Facade.CreateSFNFacade @FacadeDbName = '$(FacadeTargetDb)', @FunctionObjectId = @FunctionObjectId;

  SELECT 'Is a function.' AS resultColumn INTO #Actual
    FROM $(FacadeTargetDb).sys.objects O 
	JOIN $(FacadeTargetDb).sys.schemas S ON (O.schema_id = S.schema_id)
   WHERE O.name = 'aRandomFunction' 
	 AND S.name = @SchemaName
	 AND O.type = 'FN';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES ('Is a function.');

  EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';  END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for schema with single quote]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME('SomeRandomSchema'''+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2));
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE SCHEMA ' + @SchemaName + ';';
  EXEC(@cmd);

  SET @cmd = 'CREATE PROC ' + @SchemaName + '.AnotherProc AS RETURN 42;'; 
  EXEC(@cmd);
  
  DECLARE @ProcedureObjectId INT = OBJECT_ID(@SchemaName+'.AnotherProc');
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;

  DECLARE @RemoteProcedureName NVARCHAR(MAX) = '$(FacadeTargetDb).'+@SchemaName+'.AnotherProc'; 
  EXEC tSQLt.AssertObjectExists @ObjectName = @RemoteProcedureName;
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for procedure names with single quote]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE PROC dbo.[Anothe''rProc] AS RETURN 42;'; 
  EXEC(@cmd);
  
  DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.[Anothe''rProc]');
  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(FacadeTargetDb)', @ProcedureObjectId = @ProcedureObjectId;

  DECLARE @RemoteProcedureName NVARCHAR(MAX) = '$(FacadeTargetDb).dbo.[Anothe''rProc]'; 
  EXEC tSQLt.AssertObjectExists @ObjectName = @RemoteProcedureName;
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacade works for function names with single quote]
AS
BEGIN
  DECLARE @FakeDataSourceStatement NVARCHAR(MAX) = N'SELECT ''CREATE FUNCTION dbo.[aRando''''mFunction] () RETURNS INT AS BEGIN RETURN 1; END;'' CreateStatement';
  DECLARE @FunctionObjectId INT;

  EXEC ('CREATE FUNCTION dbo.[aRando''mFunction] () RETURNS INT AS BEGIN RETURN 1; END;');
  SET @FunctionObjectId = OBJECT_ID('dbo.[aRando''mFunction]');

  EXEC tSQLt.FakeFunction @FunctionName = N'tSQLt.Private_CreateFakeFunctionStatement',
                          @FakeDataSource = @FakeDataSourceStatement;

  EXEC Facade.CreateSFNFacade @FacadeDbName = '$(FacadeTargetDb)', @FunctionObjectId = @FunctionObjectId;

  SELECT 'Is a function.' AS resultColumn INTO #Actual
    FROM $(FacadeTargetDb).sys.objects O 
	JOIN $(FacadeTargetDb).sys.schemas S ON (O.schema_id = S.schema_id)
   WHERE O.name = 'aRando''mFunction' 
	 AND S.name = 'dbo'
	 AND O.type = 'FN';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES ('Is a function.');

  EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';

END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacades passes @FacadeDbName to CreateSSPFacade]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.procedures]';
  EXEC('INSERT INTO Facade.[sys.procedures](object_id,schema_id,name)VALUES (1001,SCHEMA_ID(''tSQLt''),''AProc'');');

  EXEC Facade.CreateSSPFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName INTO #Actual FROM Facade.[CreateSSPFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades doesn't call CreateSFNFacade if there are no functions]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateSFNFacade_SpyProcedureLog]';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades calls CreateSFNFacade if there is one function]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomFunction'',''FN'');');

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, FunctionObjectId INTO #Actual FROM Facade.[CreateSFNFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 1001);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades calls CreateSFNFacade if there are multiple functions]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1003,SCHEMA_ID(''tSQLt''),''cRandomFunction'',''FN'');');

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, FunctionObjectId INTO #Actual FROM Facade.[CreateSFNFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 1001), ('$(FacadeTargetDb)', 1002), ('$(FacadeTargetDb)', 1003);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades calls CreateSFNFacade only for functions which are not Private]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1002,SCHEMA_ID(''tSQLt''),''PrivateRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1003,SCHEMA_ID(''tSQLt''),''PrIVateRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1004,SCHEMA_ID(''tSQLt''),''PRIVATERandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1005,SCHEMA_ID(''tSQLt''),''cRandomFunction'',''FN'');');

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FunctionObjectId INTO #Actual FROM Facade.[CreateSFNFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001), (1005);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades calls CreateSFNFacade only for functions which are in the tSQLt schema]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomFunction'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1003,SCHEMA_ID(''dbo''),''cRandomFunction'',''FN'');');

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FunctionObjectId INTO #Actual FROM Facade.[CreateSFNFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001), (1002);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSFNFacades calls CreateSFNFacade only for functions]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.objects]';
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1002,SCHEMA_ID(''tSQLt''),''bRandomObject'',''IF'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1003,SCHEMA_ID(''tSQLt''),''cRandomObject'',''TF'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1004,SCHEMA_ID(''tSQLt''),''dRandomObject'',''FS'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1005,SCHEMA_ID(''tSQLt''),''eRandomObject'',''FT'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1001,SCHEMA_ID(''tSQLt''),''aRandomObject'',''FN'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1006,SCHEMA_ID(''tSQLt''),''fRandomObject'',''P'');');
  EXEC('INSERT INTO Facade.[sys.objects](object_id,schema_id,name,type)VALUES (1007,SCHEMA_ID(''tSQLt''),''gRandomObject'',''SN'');');

  EXEC Facade.CreateSFNFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FunctionObjectId INTO #Actual FROM Facade.[CreateSFNFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(1001), (1002), (1003), (1004), (1005);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacade copies a simple table type to the facade db]
AS
BEGIN
  CREATE TYPE dbo.SomeRandomType AS TABLE (a INT);

  DECLARE @UserTypeId INT = TYPE_ID('dbo.SomeRandomType');
  
  EXEC Facade.CreateTypeFacade @FacadeDbName = '$(FacadeTargetDb)', @UserTypeId = @UserTypeId;

  DECLARE @RemoteTypeId INT;
  EXEC $(FacadeTargetDb).sys.sp_executesql N'SET @TypeId = (SELECT TYPE_ID(''dbo.SomeRandomType''));',N'@TypeId INT OUTPUT', @RemoteTypeId OUT;

  EXEC tSQLt.AssertNotEquals @Expected=NULL, @Actual = @RemoteTypeId, @Message = N'Remote Type not found. ';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacade errors with appropriate message if type is not a table_type]
AS
BEGIN
  CREATE TYPE dbo.SomeRandomType FROM INT;
  DECLARE @UserTypeId INT = TYPE_ID('dbo.SomeRandomType');
  
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%CreateTypeFacade currently handles only TABLE_TYPEs%', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  EXEC Facade.CreateTypeFacade @FacadeDbName = '$(FacadeTargetDb)', @UserTypeId = @UserTypeId;
END;
GO

CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacade works for other schema that does exist in the facade db]
AS
BEGIN
  EXEC('CREATE SCHEMA SomeOtherSchemaForFacadeTests;');
  EXEC $(FacadeTargetDb).sys.sp_executesql N'EXEC(''CREATE SCHEMA SomeOtherSchemaForFacadeTests;'');',N'';

  CREATE TYPE SomeOtherSchemaForFacadeTests.SomeRandomType AS TABLE (a INT);

  DECLARE @UserTypeId INT = TYPE_ID('SomeOtherSchemaForFacadeTests.SomeRandomType');
  
  EXEC Facade.CreateTypeFacade @FacadeDbName = '$(FacadeTargetDb)', @UserTypeId = @UserTypeId;

  DECLARE @RemoteTypeId INT;
  EXEC $(FacadeTargetDb).sys.sp_executesql N'SET @TypeId = (SELECT TYPE_ID(''SomeOtherSchemaForFacadeTests.SomeRandomType''));',N'@TypeId INT OUTPUT', @RemoteTypeId OUT;

  EXEC tSQLt.AssertNotEquals @Expected=NULL, @Actual = @RemoteTypeId, @Message = N'Remote Type not found. ';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacade copies table type into a schema that does not exist in the facade db]
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = 'SomeRandomSchema'+CONVERT(NVARCHAR(MAX),CAST(NEWID() AS VARBINARY(MAX)),2);
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'CREATE SCHEMA '+@SchemaName+';';
  EXEC(@cmd);

  SET @cmd = 'CREATE TYPE ' + @SchemaName + '.SomeRandomType AS TABLE (a INT);';
  EXEC(@cmd);

  DECLARE @UserTypeId INT = TYPE_ID(@SchemaName + '.SomeRandomType');
  EXEC Facade.CreateTypeFacade @FacadeDbName = '$(FacadeTargetDb)', @UserTypeId = @UserTypeId;

  DECLARE @RemoteTypeId INT;
  SET @cmd = 'SET @TypeId = (SELECT TYPE_ID(''' + @SchemaName + '.SomeRandomType''));';
  EXEC $(FacadeTargetDb).sys.sp_executesql @cmd,N'@TypeId INT OUTPUT', @RemoteTypeId OUT;

  EXEC tSQLt.AssertNotEquals @Expected=NULL, @Actual = @RemoteTypeId, @Message = N'Remote Type not found. ';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacade copies table type with multiple columns to the facade db]
AS
BEGIN
  CREATE TYPE dbo.SomeRandomType AS TABLE (a INT, bb NVARCHAR(MAX), ccc DATETIME2);

  DECLARE @UserTypeId INT = TYPE_ID('dbo.SomeRandomType');
  
  EXEC Facade.CreateTypeFacade @FacadeDbName = '$(FacadeTargetDb)', @UserTypeId = @UserTypeId;

  DECLARE @LocalTypeTableObjectId INT = (SELECT t.type_table_object_id FROM sys.table_types t WHERE t.user_type_id = @UserTypeId);
 
  DECLARE @RemoteTypeTableObjectId INT;
  EXEC $(FacadeTargetDb).sys.sp_executesql N'SET @RemoteTypeTableObjectId = (SELECT t.type_table_object_id FROM sys.table_types t WHERE t.user_type_id = TYPE_ID(''dbo.SomeRandomType''));',N'@RemoteTypeTableObjectId INT OUTPUT', @RemoteTypeTableObjectId OUT;

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
    INTO #Actual FROM $(FacadeTargetDb).sys.columns AS C WHERE C.object_id = @RemoteTypeTableObjectId;

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
    INTO #Expected FROM sys.columns AS C WHERE C.object_id = @LocalTypeTableObjectId;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacades doesn't call CreateTypeFacade if there are no types]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.types]';

  EXEC Facade.CreateTypeFacades @FacadeDbName = '$(FacadeTargetDb)';

  EXEC tSQLt.AssertEmptyTable @TableName = 'Facade.[CreateTypeFacade_SpyProcedureLog]';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacades calls CreateTypeFacade once if there is one type]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.types]';
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (101, SCHEMA_ID(''tSQLt''),''aType'');');

  EXEC Facade.CreateTypeFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, UserTypeId INTO #Actual FROM Facade.[CreateTypeFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 101);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacades calls CreateTypeFacade once each for multiple types]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.types]';
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (101, SCHEMA_ID(''tSQLt''),''aType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (102, SCHEMA_ID(''tSQLt''),''bType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (103, SCHEMA_ID(''tSQLt''),''cType'');');

  EXEC Facade.CreateTypeFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, UserTypeId INTO #Actual FROM Facade.[CreateTypeFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 101),('$(FacadeTargetDb)', 102),('$(FacadeTargetDb)', 103);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacades calls CreateTypeFacade only for types which are in the tSQLt schema]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.types]';
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (101, SCHEMA_ID(''tSQLt''),''aType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (102, SCHEMA_ID(''dbo''),''bType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (103, SCHEMA_ID(''tSQLt''),''cType'');');

  EXEC Facade.CreateTypeFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, UserTypeId INTO #Actual FROM Facade.[CreateTypeFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 101),('$(FacadeTargetDb)', 103);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateTypeFacades calls CreateTypeFacade only for types which are not Private]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacade';
  EXEC tSQLt.FakeTable @TableName = 'Facade.[sys.types]';
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (101, SCHEMA_ID(''tSQLt''),''aType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (102, SCHEMA_ID(''tSQLt''),''bType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (103, SCHEMA_ID(''tSQLt''),''PrivateType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (104, SCHEMA_ID(''tSQLt''),''PRIVATEType'');');
  EXEC ('INSERT INTO Facade.[sys.types] (user_type_id, schema_id, name) VALUES (105, SCHEMA_ID(''tSQLt''),''PrIVateType'');');

  EXEC Facade.CreateTypeFacades @FacadeDbName = '$(FacadeTargetDb)';

  SELECT FacadeDbName, UserTypeId INTO #Actual FROM Facade.[CreateTypeFacade_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)', 101),('$(FacadeTargetDb)', 102);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateAllFacadeObjects calls all Facades procedures]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacades';

  EXEC Facade.CreateAllFacadeObjects @FacadeDbName = '$(FacadeTargetDb)';

  SELECT * INTO #Actual FROM
  (
    SELECT FacadeDbName, 'UDT' AS [Procedure] FROM Facade.[CreateTypeFacades_SpyProcedureLog]
    UNION ALL
    SELECT FacadeDbName, 'SFN' AS [Procedure] FROM Facade.[CreateSFNFacades_SpyProcedureLog]
    UNION ALL
    SELECT FacadeDbName, 'SSP' AS [Procedure] FROM Facade.[CreateSSPFacades_SpyProcedureLog]
    UNION ALL
    SELECT FacadeDbName, 'TBL' AS [Procedure] FROM Facade.[CreateTableFacades_SpyProcedureLog]
    UNION ALL
    SELECT FacadeDbName, 'VW' AS [Procedure] FROM Facade.[CreateViewFacades_SpyProcedureLog]
  ) SPL;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('$(FacadeTargetDb)','UDT'),('$(FacadeTargetDb)','SFN'), ('$(FacadeTargetDb)','SSP'), ('$(FacadeTargetDb)','TBL'), ('$(FacadeTargetDb)','VW');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateAllFacadeObjects doesn't error]
AS
BEGIN
  EXEC tSQLt.ExpectNoException;

  EXEC Facade.CreateAllFacadeObjects @FacadeDbName = '$(FacadeTargetDb)';
END;
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateAllFacadeObjects creates the tSQLt.TestClass user]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSFNFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateSSPFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTableFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateViewFacades';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'Facade.CreateTypeFacades';

  EXEC Facade.CreateAllFacadeObjects @FacadeDbName = '$(FacadeTargetDb)';

  DECLARE @RemoteDatabasePrincipalId INT;
  EXEC $(FacadeTargetDb).sys.sp_executesql N'SET @RemoteDatabasePrincipalId = USER_ID(''tSQLt.TestClass'');',N'@RemoteDatabasePrincipalId INT OUTPUT', @RemoteDatabasePrincipalId OUT;

  EXEC tSQLt.AssertNotEquals @Expected=NULL, @Actual = @RemoteDatabasePrincipalId, @Message = N'Remote Database Principal Id not found. ';
END;
GO
