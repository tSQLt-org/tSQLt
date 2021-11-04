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

   EXEC tSQLt.Private_RenameObjectToUniqueName @OrigObjectCleanQuotedSchemaName, @OrigObjectCleanQuotedName, @OrigObjectNewName OUTPUT;

   SELECT @TargetObjectFullName = S.base_object_name
     FROM sys.synonyms AS S 
    WHERE S.object_id = OBJECT_ID(@OrigObjectCleanQuotedSchemaName + '.' + @OrigObjectNewName);

   IF(@TargetObjectFullName IS NOT NULL)
   BEGIN
     IF(COALESCE(OBJECT_ID(@TargetObjectFullName,'U'),OBJECT_ID(@TargetObjectFullName,'V')) IS NULL)
     BEGIN
       RAISERROR('Cannot fake synonym %s as it is pointing to %s, which is not a table or view!',16,10,@OrigObjectFullName,@TargetObjectFullName);
     END;
   END;
   ELSE
   BEGIN
     SET @TargetObjectFullName = @OrigObjectCleanQuotedSchemaName + '.' + QUOTENAME(@OrigObjectNewName); --TODO:Test for QUOTENAME
   END;

   EXEC tSQLt.Private_CreateFakeOfTable @OrigObjectCleanQuotedSchemaName, @OrigObjectCleanQuotedName, @TargetObjectFullName, @Identity, @ComputedColumns, @Defaults;

   EXEC tSQLt.Private_MarktSQLtTempObject @OrigObjectFullName, @OrigObjectNewName;
END
---Build-
GO
