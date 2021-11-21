IF OBJECT_ID('tSQLt.SpyProcedure') IS NOT NULL DROP PROCEDURE tSQLt.SpyProcedure;
GO
---Build+
CREATE PROCEDURE tSQLt.SpyProcedure
    @ProcedureName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @ProcedureObjectId INT;
    SELECT @ProcedureObjectId = OBJECT_ID(@ProcedureName);

    EXEC tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure @ProcedureName;

    DECLARE @LogTableName NVARCHAR(MAX);
    SELECT @LogTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@ProcedureObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@ProcedureObjectId)+'_SpyProcedureLog');

    DECLARE @CreateProcedureStatement NVARCHAR(MAX);
    DECLARE @CreateLogTableStatement NVARCHAR(MAX);

    EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement
           @ProcedureObjectId = @ProcedureObjectId,
           @OriginalProcedureName = @ProcedureName,
           @LogTableName = @LogTableName,
           @CommandToExecute = @CommandToExecute,
           @CreateProcedureStatement = @CreateProcedureStatement OUT,
           @CreateLogTableStatement = @CreateLogTableStatement OUT;
    
    DECLARE @NewNameOfOriginalObject NVARCHAR(MAX);


    DECLARE @LogTableObjectId INT = OBJECT_ID(@LogTableName);
    IF(@LogTableObjectId IS NOT NULL)
    BEGIN
      EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ObjectId = @LogTableObjectId;
    END;
    EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ProcedureObjectId, @NewName = @NewNameOfOriginalObject OUTPUT;
    EXEC(@CreateLogTableStatement);

    EXEC(@CreateProcedureStatement);

    EXEC tSQLt.Private_MarktSQLtTempObject @ProcedureName, N'PROCEDURE', @NewNameOfOriginalObject;
    EXEC tSQLt.Private_MarktSQLtTempObject @LogTableName, N'TABLE', NULL;

    RETURN 0;
END;
---Build-
GO
