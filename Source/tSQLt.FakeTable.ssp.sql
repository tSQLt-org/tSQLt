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
   DECLARE @OrigSchemaName NVARCHAR(MAX);
   DECLARE @OrigTableName NVARCHAR(MAX);
   DECLARE @NewNameOfOriginalTable NVARCHAR(4000);
   DECLARE @OrigTableFullName NVARCHAR(MAX); SET @OrigTableFullName = NULL;
   DECLARE @RemoteObjectID INT;
   DECLARE @SynonymObjectId INT;

   SELECT @OrigSchemaName = @SchemaName,
          @OrigTableName = @TableName
   
   IF(@OrigTableName NOT IN (PARSENAME(@OrigTableName,1),QUOTENAME(PARSENAME(@OrigTableName,1)))
      AND @OrigSchemaName IS NOT NULL)
      BEGIN
        RAISERROR('When @TableName is a multi-part identifier, @SchemaName must be NULL!',16,10);
      END

   SELECT @SchemaName = CleanSchemaName,
          @TableName = CleanTableName
     FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility(@TableName, @SchemaName);
   
   EXEC tSQLt.Private_ValidateFakeTableParameters @SchemaName,@OrigTableName,@OrigSchemaName;

   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @TableName, @NewNameOfOriginalTable OUTPUT;


   SET @OrigTableFullName = @SchemaName + '.' + @NewNameOfOriginalTable;
   SET @SynonymObjectId =    OBJECT_ID(@OrigTableFullName, 'SN');
   IF ( @SynonymObjectId > 0)
      BEGIN
          EXEC tSQLt.Private_GetRemoteObjectId @SynonymObjectId = @SynonymObjectId ,
                                               @RemoteObjectId = @RemoteObjectID OUTPUT,
                                               @OrigTableFullName = @OrigTableFullName OUTPUT

          EXEC tSQLt.Private_ValidateSynonymCompatibilityWithFakeTable @TableName, @SchemaName, @OrigTableFullName;
      END;

   EXEC tSQLt.Private_CreateFakeOfTable @SchemaName, @TableName, @OrigTableFullName, @Identity, @ComputedColumns, @Defaults, @RemoteObjectID;

   EXEC tSQLt.Private_MarkFakeTable @SchemaName, @TableName, @NewNameOfOriginalTable;

   IF (@RemoteObjectID IS NOT NULL)
   BEGIN
     EXEC tSQLt.Private_CreateRemoteSysObjects @Instance = NULL, @Database = NULL;
   END

END
---Build-
GO
