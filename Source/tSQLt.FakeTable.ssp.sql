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

   SELECT @OrigTableFullName = S.base_object_name
     FROM sys.synonyms AS S 
    WHERE S.object_id = OBJECT_ID(@SchemaName + '.' + @NewNameOfOriginalTable);

  IF ( @OrigTableFullName IS NOT NULL )
      BEGIN
          IF ( PARSENAME(@OrigTableFullName, 3) IS NOT NULL )
              BEGIN

                  DECLARE @Cmd NVARCHAR(MAX);
                  DECLARE @params NVARCHAR(MAX); SET @params = '@RemoteObjectID INT OUT, @OrigTableFullName NVARCHAR(MAX)';
                  
                  EXEC tSQLt.Private_GetRemoteObjectId @OrigTableFullName = @OrigTableFullName ,
                                                        @RemoteObjectId = @RemoteObjectID OUTPUT
              END;

          IF ( COALESCE(OBJECT_ID(@OrigTableFullName, 'U'),
                        OBJECT_ID(@OrigTableFullName, 'V'),
                        @RemoteObjectID) IS NULL )
              BEGIN
                  RAISERROR('Cannot fake synonym %s.%s as it is pointing to %s, which is not a table or view!',16,10,@SchemaName,@TableName,@OrigTableFullName);
              END;
          ELSE 
            BEGIN
            
                  DECLARE @Database NVARCHAR(MAX); SET @Database = PARSENAME(@OrigTableFullName, 3);
                  DECLARE @Instance NVARCHAR(MAX); SET @Instance = PARSENAME(@OrigTableFullName, 4);

                  EXEC tSQLt.Private_CreateRemoteSysObjects @Instance = @Instance, @Database = @Database;
            END
      END;
   ELSE
   BEGIN
     SET @OrigTableFullName = @SchemaName + '.' + @NewNameOfOriginalTable;
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
