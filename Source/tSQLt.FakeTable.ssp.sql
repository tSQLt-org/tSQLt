IF OBJECT_ID('tSQLt.FakeTable') IS NOT NULL DROP PROCEDURE tSQLt.FakeTable;
GO
---Build+
CREATE PROCEDURE tSQLt.FakeTable
    @TableName NVARCHAR(MAX),
    @SchemaName NVARCHAR(MAX) = NULL, --parameter preserved for backward compatibility. Do not use. Will be removed soon.
    @Identity BIT = NULL,
    @ComputedColumns BIT = NULL,
    @Defaults BIT = NULL
AS
BEGIN
   DECLARE @OrigObjectCleanQuotedSchemaName NVARCHAR(MAX);
   DECLARE @OrigObjectCleanQuotedName NVARCHAR(MAX);
   DECLARE @OrigObjectNewName NVARCHAR(4000);
   DECLARE @OrigObjectFullName NVARCHAR(MAX) = NULL;
   DECLARE @TargetObjectFullName NVARCHAR(MAX) = NULL;
   DECLARE @OriginalObjectObjectId INT;
   DECLARE @TargetObjectObjectId INT;
   DECLARE @IsNode BIT = 0;
   DECLARE @IsEdge BIT = 0;

   IF(@TableName NOT IN (PARSENAME(@TableName,1),QUOTENAME(PARSENAME(@TableName,1)))
      AND @SchemaName IS NOT NULL)
   BEGIN
     RAISERROR('When @TableName is a multi-part identifier, @SchemaName must be NULL!',16,10);
   END

   SELECT @OrigObjectCleanQuotedSchemaName = CleanSchemaName,
          @OrigObjectCleanQuotedName = CleanTableName
     FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility(@TableName, @SchemaName);
   
   EXEC tSQLt.Private_ValidateFakeTableParameters @OrigObjectCleanQuotedSchemaName,@TableName,@SchemaName;

   SET @OrigObjectFullName = @OrigObjectCleanQuotedSchemaName + '.' + @OrigObjectCleanQuotedName;

  -- Retrieve node and edge information for the original object
   SELECT
      @IsNode = is_node, @IsEdge = is_edge FROM sys.tables
    WHERE [name] = PARSENAME(@OrigObjectFullName,1) AND schema_name([schema_id]) = PARSENAME(@OrigObjectFullName,2);

   EXEC tSQLt.Private_RenameObjectToUniqueName @OrigObjectCleanQuotedSchemaName, @OrigObjectCleanQuotedName, @OrigObjectNewName OUTPUT;

   SET @OriginalObjectObjectId = OBJECT_ID(@OrigObjectCleanQuotedSchemaName + '.' + QUOTENAME(@OrigObjectNewName));

   SELECT @TargetObjectFullName = S.base_object_name
     FROM sys.synonyms AS S 
    WHERE S.object_id = @OriginalObjectObjectId;

   IF(@TargetObjectFullName IS NOT NULL)
   BEGIN
     IF(COALESCE(OBJECT_ID(@TargetObjectFullName,'U'),OBJECT_ID(@TargetObjectFullName,'V')) IS NULL)
     BEGIN
       RAISERROR('Cannot fake synonym %s as it is pointing to %s, which is not a table or view!',16,10,@OrigObjectFullName,@TargetObjectFullName);
     END;
     SET @TargetObjectObjectId = OBJECT_ID(@TargetObjectFullName);
   END;
   ELSE
   BEGIN
     SET @TargetObjectObjectId = @OriginalObjectObjectId;
   END;

   EXEC tSQLt.Private_CreateFakeOfTable @OrigObjectCleanQuotedSchemaName, @OrigObjectCleanQuotedName, @TargetObjectObjectId, @Identity, @ComputedColumns, @Defaults, @IsNode, @IsEdge;

   EXEC tSQLt.Private_MarktSQLtTempObject @OrigObjectFullName, N'TABLE', @OrigObjectNewName;
END
---Build-
GO
