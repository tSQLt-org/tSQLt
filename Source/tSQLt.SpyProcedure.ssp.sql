IF OBJECT_ID('tSQLt.SpyProcedure') IS NOT NULL DROP PROCEDURE tSQLt.SpyProcedure;
GO
---Build+
CREATE PROCEDURE tSQLt.SpyProcedure
    @ProcedureName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @ProcedureObjectId INT;
    DECLARE @OriginalObjectId INT;
	DECLARE @SpyProcedureName NVARCHAR(MAX);
	DECLARE @RemoteObjectName NVARCHAR(MAX);
    SELECT @OriginalObjectId = OBJECT_ID(@ProcedureName);
	SELECT @ProcedureObjectId = @OriginalObjectId;


    EXEC tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure @ProcedureName;

	SELECT 
	    @ProcedureObjectId = OBJECT_ID(s.base_object_name),
		@RemoteObjectName = s.base_object_name
	  FROM sys.synonyms AS s WHERE s.object_id = @OriginalObjectId;

    DECLARE @LogTableName NVARCHAR(MAX);
    SELECT @LogTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@OriginalObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@OriginalObjectId)+'_SpyProcedureLog');
	SELECT @SpyProcedureName = QUOTENAME(OBJECT_SCHEMA_NAME(@OriginalObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@OriginalObjectId));

    DECLARE @CreateProcedureStatement NVARCHAR(MAX);
    DECLARE @CreateLogTableStatement NVARCHAR(MAX);

    EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement
           @ProcedureObjectId = @ProcedureObjectId,
           @OriginalProcedureName = @SpyProcedureName,
           @LogTableName = @LogTableName,
           @CommandToExecute = @CommandToExecute,
		   @RemoteObjectName = @RemoteObjectName,
           @CreateProcedureStatement = @CreateProcedureStatement OUT,
           @CreateLogTableStatement = @CreateLogTableStatement OUT;
    

    EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @OriginalObjectId;

    EXEC(@CreateLogTableStatement);

    EXEC(@CreateProcedureStatement);

    RETURN 0;
END;
---Build-
GO
