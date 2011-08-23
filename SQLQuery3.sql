DROP FUNCTION tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility;
GO

CREATE FUNCTION tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility 
 (@TableName NVARCHAR(MAX), @SchemaName NVARCHAR(MAX))
RETURNS TABLE AS 
RETURN
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) AS CleanSchemaName,
         QUOTENAME(OBJECT_NAME(object_id)) AS CleanTableName
     FROM (SELECT CASE
                    WHEN @SchemaName IS NULL THEN OBJECT_ID(@TableName)
                    ELSE COALESCE(OBJECT_ID(@SchemaName + '.' + @TableName),OBJECT_ID(@TableName + '.' + @SchemaName)) 
                  END object_id
          ) ids;
GO

DROP PROCEDURE tSQLt.FakeTable;
GO
CREATE PROCEDURE tSQLt.FakeTable
    @TableName NVARCHAR(MAX),
    @SchemaName NVARCHAR(MAX) = NULL --parameter preserved for backward compatibility. Do not use. Will be removed soon.
AS
BEGIN

   DECLARE @OrigSchemaName NVARCHAR(MAX);
   DECLARE @OrigTableName NVARCHAR(MAX);
   DECLARE @NewName NVARCHAR(4000);
   DECLARE @Cmd NVARCHAR(MAX);
   
   SELECT @OrigSchemaName = @SchemaName,
          @OrigTableName = @TableName
   --SET @SchemaName = tSQLt.Private_GetCleanSchemaName(@SchemaName, @TableName);
   
   SELECT @SchemaName = CleanSchemaName,
          @TableName = CleanTableName
     FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility(@TableName, @SchemaName);
   
   IF @SchemaName IS NULL
   BEGIN
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = 
            '''' + COALESCE(@OrigTableName+'.', '') + COALESCE(@OrigSchemaName, 'NULL') + 
            ''' does not exist.';
        RAISERROR (@ErrorMessage, 16, 10);
   END;

   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @TableName, @NewName OUTPUT

   SELECT @Cmd = 'DECLARE @N TABLE(n INT IDENTITY(1,1));
      SELECT Src.*
        INTO ' + @SchemaName + '.' + @TableName + '
        FROM ' + @SchemaName + '.' + @NewName + ' Src
       RIGHT JOIN @N AS n
          ON n.n<>n.n
       WHERE n.n<>n.n
   ';
   EXEC (@Cmd);

   EXEC sys.sp_addextendedproperty 
      @name = N'tSQLt.FakeTable_OrgTableName', 
      @value = @NewName, 
      @level0type = N'SCHEMA', @level0name = @SchemaName, 
      @level1type = N'TABLE',  @level1name = @TableName;
END
GO