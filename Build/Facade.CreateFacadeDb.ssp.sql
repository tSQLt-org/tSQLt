EXEC tSQLt.DropClass 'Facade';
GO
CREATE SCHEMA Facade;
GO
CREATE PROCEDURE Facade.CreateSchemaIfNotExists
  @FacadeDbName NVARCHAR(MAX), 
  @SchemaName NVARCHAR(MAX) 
AS
BEGIN
  DECLARE @ExecInRemoteDb NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @RemoteStatement NVARCHAR(MAX);

  DECLARE @RemoteSchemaId INT;
  SET @RemoteStatement = N'SET @RemoteSchemaId = SCHEMA_ID('''+PARSENAME(@SchemaName,1)+''');'
  EXEC @ExecInRemoteDb @RemoteStatement, N'@RemoteSchemaId INT OUTPUT',@RemoteSchemaId OUT; 
  IF(@RemoteSchemaId IS NULL)
  BEGIN
    SET @RemoteStatement = 'EXEC(''CREATE SCHEMA '+@SchemaName+';'');';
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

  SET @RemoteStatement = 'EXEC('''+@CreateProcedureStatement+''');';
  EXEC @ExecInRemoteDb @RemoteStatement,N'';

  RETURN;
END;
GO
CREATE VIEW Facade.[sys.procedures] AS SELECT * FROM sys.procedures AS P;
GO
CREATE PROCEDURE Facade.CreateSSPFacades
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = 
    (
      SELECT 'EXEC Facade.CreateSSPFacade @ProcedureObjectId = '+CAST(object_id AS NVARCHAR(MAX))+';'
        FROM Facade.[sys.procedures]
       WHERE schema_id = SCHEMA_ID('tSQLt')
         AND name NOT LIKE 'Private[_]%'
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO