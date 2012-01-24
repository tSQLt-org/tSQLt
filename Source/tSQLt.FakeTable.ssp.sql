IF OBJECT_ID('tSQLt.FakeTable') IS NOT NULL DROP PROCEDURE tSQLt.FakeTable;
GO
--Build+
CREATE PROCEDURE tSQLt.FakeTable
    @TableName NVARCHAR(MAX),
    @SchemaName NVARCHAR(MAX) = NULL, --parameter preserved for backward compatibility. Do not use. Will be removed soon.
    @Identity BIT = NULL
AS
BEGIN
   DECLARE @OrigSchemaName NVARCHAR(MAX);
   DECLARE @OrigTableName NVARCHAR(MAX);
   DECLARE @NewName NVARCHAR(4000);
   DECLARE @Cmd NVARCHAR(MAX);
   
   SELECT @OrigSchemaName = @SchemaName,
          @OrigTableName = @TableName
   
   SELECT @SchemaName = CleanSchemaName,
          @TableName = CleanTableName
     FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility(@TableName, @SchemaName);
   
   IF @SchemaName IS NULL
   BEGIN
        DECLARE @FullName NVARCHAR(MAX); SET @FullName = @OrigTableName + COALESCE('.' + @OrigSchemaName, '');
        
        RAISERROR ('FakeTable could not resolve the object name, ''%s''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''', 
                   16, 10, @FullName);
   END;

   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @TableName, @NewName OUTPUT

   IF @Identity = 1
   BEGIN
     SET @cmd = (
       SELECT 'IDENTITY(INT,1,1) AS ' + QUOTENAME([name])
         FROM sys.columns
        WHERE object_id = OBJECT_ID(@SchemaName + '.' + @NewName)
          AND is_identity = 1);
   END;

   SET @Cmd = ISNULL(@cmd,'CAST(NULL AS INT) AS i');

   SELECT @Cmd = 'DECLARE @N TABLE(n INT );
      SELECT '+@cmd+' 
        INTO ' + @SchemaName + '.' + @TableName + '
        FROM ' + @SchemaName + '.' + @NewName + ' Src
        RIGHT JOIN @N AS n
          ON n.n<>n.n
       WHERE n.n<>n.n;
   ';
   EXEC (@Cmd);



   DECLARE @UnquotedSchemaName NVARCHAR(MAX);SET @UnquotedSchemaName = OBJECT_SCHEMA_NAME(OBJECT_ID(@SchemaName+'.'+@TableName));
   DECLARE @UnquotedTableName NVARCHAR(MAX);SET @UnquotedTableName = OBJECT_NAME(OBJECT_ID(@SchemaName+'.'+@TableName));

   EXEC sys.sp_addextendedproperty 
      @name = N'tSQLt.FakeTable_OrgTableName', 
      @value = @NewName, 
      @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
      @level1type = N'TABLE',  @level1name = @UnquotedTableName;
END
--Build-
GO