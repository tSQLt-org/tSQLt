EXEC tSQLt.DropClass 'Facade';
GO
CREATE SCHEMA Facade;
GO
CREATE VIEW Facade.[sys.tables] AS SELECT * FROM sys.tables;
GO
CREATE VIEW Facade.[sys.views] AS SELECT * FROM sys.views;
GO
CREATE VIEW Facade.[sys.procedures] AS SELECT * FROM sys.procedures;
GO
CREATE VIEW Facade.[sys.objects] AS SELECT * FROM sys.objects;
GO
CREATE VIEW Facade.[sys.types] AS SELECT * FROM sys.types;
GO
CREATE PROCEDURE Facade.CreateSchemaIfNotExists
  @FacadeDbName NVARCHAR(MAX), 
  @SchemaName NVARCHAR(MAX) 
AS
BEGIN
  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  DECLARE @RemoteSchemaId INT;
  SET @RemoteStatement = N'SET @RemoteSchemaId = SCHEMA_ID(''' + REPLACE(PARSENAME(@SchemaName,1),'''','''''') +''');'
  EXEC @ExecInRemoteDb @RemoteStatement, N'@RemoteSchemaId INT OUTPUT',@RemoteSchemaId OUT; 
  IF(@RemoteSchemaId IS NULL)
  BEGIN
    SET @RemoteStatement = 'EXEC(''CREATE SCHEMA ' + REPLACE(@SchemaName,'''','''''') +';'');';
    EXEC @ExecInRemoteDb @RemoteStatement,N'';
  END;   
END;
GO
CREATE PROCEDURE Facade.CreateSSPFacade
  @FacadeDbName NVARCHAR(MAX), 
  @ProcedureObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME(OBJECT_SCHEMA_NAME(@ProcedureObjectId));
  DECLARE @ProcedureName NVARCHAR(MAX) = @SchemaName+'.'+QUOTENAME(OBJECT_NAME(@ProcedureObjectId));
  DECLARE @CreateProcedureStatement NVARCHAR(MAX);

  EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement 
         @ProcedureObjectId = @ProcedureObjectId,
         @OriginalProcedureName = @ProcedureName,
         @CreateProcedureStatement = @CreateProcedureStatement OUT,
         @LogTableName = NULL,
         @CommandToExecute = NULL,
         @CreateLogTableStatement = NULL;
  
  EXEC Facade.CreateSchemaIfNotExists @FacadeDbName = @FacadeDbName, @SchemaName = @SchemaName;

  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  SET @RemoteStatement = 'EXEC(''' + REPLACE(@CreateProcedureStatement,'''','''''') + ''');';
  EXEC @ExecInRemoteDb @RemoteStatement,N'';
END;
GO
CREATE PROCEDURE Facade.CreateSSPFacades
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = 
    (
      SELECT 'EXEC Facade.CreateSSPFacade @FacadeDbName = @FacadeDbName, @ProcedureObjectId = '+CAST(object_id AS NVARCHAR(MAX))+';'
        FROM Facade.[sys.procedures]
       WHERE schema_id = SCHEMA_ID('tSQLt')
         AND UPPER(name) NOT LIKE 'PRIVATE%'
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');

	EXEC sys.sp_executesql @cmd, N'@FacadeDbName NVARCHAR(MAX)', @FacadeDbName;
END;
GO
CREATE PROCEDURE Facade.CreateTableFacade
  @FacadeDbName NVARCHAR(MAX), 
  @TableObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME(OBJECT_SCHEMA_NAME(@TableObjectId));
  DECLARE @TableName NVARCHAR(MAX) = QUOTENAME(OBJECT_NAME(@TableObjectId));
  DECLARE @OrigTableFullName NVARCHAR(MAX) = @SchemaName+'.'+@TableName
  DECLARE @CreateTableStatement NVARCHAR(MAX) = 
     (SELECT CreateTableStatement FROM tSQLt.Private_CreateFakeTableStatement(@TableObjectId,@OrigTableFullName,1,1,1,1));
  
  EXEC Facade.CreateSchemaIfNotExists @FacadeDbName = @FacadeDbName, @SchemaName = @SchemaName;

  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  SET @RemoteStatement = 'EXEC(''' + REPLACE(@CreateTableStatement,'''','''''') + ''');';
  EXEC @ExecInRemoteDb @RemoteStatement,N'';
END;
GO
CREATE PROCEDURE Facade.CreateTableFacades
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN
	DECLARE @cmd NVARCHAR(MAX) = 
 (
   SELECT 'EXEC Facade.CreateTableFacade @FacadeDbName = @FacadeDbName, @TableObjectId = ' + CAST(object_id AS NVARCHAR(MAX)) + ';'
     FROM (SELECT object_id, name, schema_id FROM Facade.[sys.tables] UNION ALL SELECT object_id, name, schema_id FROM Facade.[sys.views]) T
    WHERE UPPER(T.name) NOT LIKE 'PRIVATE%'
      AND T.schema_id = SCHEMA_ID('tSQLt')
      FOR XML PATH (''),TYPE
 ).value('.','NVARCHAR(MAX)');
    
	EXEC sys.sp_executesql @cmd, N'@FacadeDbName NVARCHAR(MAX)', @FacadeDbName;

	RETURN;
END;
GO
CREATE PROCEDURE Facade.CreateViewFacade
  @FacadeDbName NVARCHAR(MAX),
  @ViewObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME(OBJECT_SCHEMA_NAME(@ViewObjectId));
  DECLARE @ViewName NVARCHAR(MAX) = QUOTENAME(OBJECT_NAME(@ViewObjectId));
  DECLARE @OrigViewFullName NVARCHAR(MAX) = @SchemaName+'.'+@ViewName
  DECLARE @CreateViewStatement NVARCHAR(MAX);

  SELECT @CreateViewStatement = 
      'CREATE VIEW ' + @OrigViewFullName + 
      ' AS ' + 
      TypeOnlySelectStatement 
    FROM  tSQLt.Private_CreateFakeFunctionStatement(@ViewObjectId, NULL);

  EXEC Facade.CreateSchemaIfNotExists @FacadeDbName = @FacadeDbName, @SchemaName = @SchemaName;
    
  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  SET @RemoteStatement = 'EXEC(''' + REPLACE(@CreateViewStatement,'''','''''') + ''');'; /* Wrapping this in an EXEC makes sure it is executed in its own "batch". */
  
  EXEC @ExecInRemoteDb @RemoteStatement,N'';
  RETURN;
END;
GO
CREATE PROCEDURE Facade.CreateViewFacades
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN
	 DECLARE @cmd NVARCHAR(MAX) = 
  (
    SELECT 'EXEC Facade.CreateViewFacade @FacadeDbName = @FacadeDbName, @ViewObjectId = ' + CAST(object_id AS NVARCHAR(MAX)) + ';'
      FROM Facade.[sys.views] V
     WHERE UPPER(V.name) NOT LIKE 'PRIVATE%'
       AND V.schema_id = SCHEMA_ID('tSQLt')
       FOR XML PATH (''),TYPE
  ).value('.','NVARCHAR(MAX)');
    
	 EXEC sys.sp_executesql @cmd, N'@FacadeDbName NVARCHAR(MAX)', @FacadeDbName;
  RETURN;
END;
GO

CREATE PROCEDURE Facade.CreateSFNFacade
  @FacadeDbName NVARCHAR(MAX), 
  @FunctionObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME(OBJECT_SCHEMA_NAME(@FunctionObjectId));

  EXEC Facade.CreateSchemaIfNotExists @FacadeDbName = @FacadeDbName, @SchemaName = @SchemaName;

  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFakeFunctionStatement(@FunctionObjectId, NULL));

  SET @RemoteStatement = 'EXEC('''+REPLACE(@RemoteStatement,'''','''''')+''');';

  EXEC @ExecInRemoteDb @RemoteStatement,N'';
END;
GO
CREATE PROCEDURE Facade.CreateSFNFacades
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN
	DECLARE @cmd NVARCHAR(MAX) = 
 (
   SELECT 'EXEC Facade.CreateSFNFacade @FacadeDbName = @FacadeDbName, @FunctionObjectId = ' + CAST(object_id AS NVARCHAR(MAX)) + ';'
     FROM Facade.[sys.objects] O
    WHERE UPPER(O.name) NOT LIKE 'PRIVATE%'
      AND O.schema_id = SCHEMA_ID('tSQLt')
      AND O.type IN ('IF', 'TF', 'FS', 'FT', 'FN')
      FOR XML PATH (''),TYPE
 ).value('.','NVARCHAR(MAX)');

	EXEC sys.sp_executesql @cmd, N'@FacadeDbName NVARCHAR(MAX)', @FacadeDbName;
END;
GO
CREATE PROCEDURE Facade.CreateTypeFacade 
  @FacadeDbName NVARCHAR(MAX),
  @UserTypeId INT
AS
BEGIN
  DECLARE @TypeTableObjectId INT;
  DECLARE @TypeSchemaId INT;
  SELECT @TypeTableObjectId = tt.type_table_object_id, @TypeSchemaId = tt.schema_id FROM sys.table_types tt WHERE tt.user_type_id = @UserTypeId;

  IF (@TypeTableObjectId IS NULL)
  BEGIN
    RAISERROR ('CreateTypeFacade currently handles only TABLE_TYPEs', 16, 10);
    RETURN;
  END

  DECLARE @SchemaName NVARCHAR(MAX) = QUOTENAME(SCHEMA_NAME(@TypeSchemaId));
  DECLARE @TypeName NVARCHAR(MAX) = QUOTENAME(TYPE_NAME(@UserTypeId));

  DECLARE @FullTypeName NVARCHAR(MAX) = @SchemaName+'.'+@TypeName;
  DECLARE @CreateTableStatement NVARCHAR(MAX) = 
     (SELECT CreateTableTypeStatement FROM tSQLt.Private_CreateFakeTableStatement(@TypeTableObjectId,@FullTypeName,1,1,1,1));
  
  EXEC Facade.CreateSchemaIfNotExists @FacadeDbName = @FacadeDbName, @SchemaName = @SchemaName;

  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  SET @RemoteStatement = 'EXEC(''' + REPLACE(@CreateTableStatement,'''','''''') + ''');';
  EXEC @ExecInRemoteDb @RemoteStatement,N'';
  
END;
GO
CREATE PROCEDURE Facade.CreateTypeFacades 
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) =
  (
    SELECT 'EXEC Facade.CreateTypeFacade @FacadeDbName = @FacadeDbName, @UserTypeId =  ' + CAST(t.user_type_id AS NVARCHAR(MAX)) + ';'
      FROM Facade.[sys.types] t
     WHERE t.schema_id = SCHEMA_ID('tSQLt')
       AND UPPER(t.name) NOT LIKE ('PRIVATE%')
       FOR XML PATH (''),TYPE
  ).value('.','NVARCHAR(MAX)');

 	EXEC sys.sp_executesql @cmd, N'@FacadeDbName NVARCHAR(MAX)', @FacadeDbName;
END;
GO
CREATE PROCEDURE Facade.CreateAllFacadeObjects
  @FacadeDbName NVARCHAR(MAX)
AS
BEGIN

  EXEC Facade.CreateTypeFacades @FacadeDbName = @FacadeDbName;
  EXEC Facade.CreateTableFacades @FacadeDbName = @FacadeDbName;
  EXEC Facade.CreateViewFacades @FacadeDbName = @FacadeDbName;
  EXEC Facade.CreateSSPFacades @FacadeDbName = @FacadeDbName;
  EXEC Facade.CreateSFNFacades @FacadeDbName = @FacadeDbName;

  DECLARE @ExecuteInFacadeDb NVARCHAR(MAX) = @FacadeDbName + '.sys.sp_executesql';
  EXEC @ExecuteInFacadeDb N'CREATE USER [tSQLt.TestClass] WITHOUT LOGIN;', N'';

END;
GO

