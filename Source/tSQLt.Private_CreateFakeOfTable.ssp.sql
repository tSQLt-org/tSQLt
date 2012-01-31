IF OBJECT_ID('tSQLt.Private_CreateFakeOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeOfTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @NewNameOfOriginalTable NVARCHAR(MAX),
  @Identity BIT
AS
BEGIN
   DECLARE @Cmd NVARCHAR(MAX);
      
   SET @Cmd = 
   (
    SELECT 
      ',' +
      CASE WHEN is_identity = 1 AND @Identity = 1 
           THEN (SELECT IdentityClause 
                   FROM tSQLt.Private_BuildIdentityClause(user_type_id, precision, @SchemaName + '.' + @NewNameOfOriginalTable)) + 
                ' AS ' 
           ELSE '' 
      END +
      QUOTENAME(name)
      FROM sys.columns
     WHERE object_id = OBJECT_ID(@SchemaName + '.' + @NewNameOfOriginalTable)
     ORDER BY column_id
     FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');
   
   SELECT @Cmd = 'DECLARE @N TABLE(n INT );
      SELECT '+STUFF(@Cmd,1,1,'')+' 
        INTO ' + @SchemaName + '.' + @TableName + '
        FROM ' + @SchemaName + '.' + @NewNameOfOriginalTable + ' Src
        RIGHT JOIN @N AS n
          ON n.n<>n.n
       WHERE n.n<>n.n;
   ';
   
   EXEC (@Cmd);
END;
---Build-
GO
