IF OBJECT_ID('tSQLt.Private_CreateFakeOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeOfTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @NewNameOfOriginalTable NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT
AS
BEGIN
   DECLARE @Cmd NVARCHAR(MAX);
   DECLARE @Cols NVARCHAR(MAX);
   
   SELECT @Cols = 
   (
    SELECT
       ',' +
       QUOTENAME(name) + 
       ' ' + CASE WHEN is_computed = 1 AND @ComputedColumns = 1
                  THEN 'AS ' + (SELECT definition FROM sys.computed_columns WHERE sys.computed_columns.object_id = sys.columns.object_id AND sys.computed_columns.column_id = sys.columns.column_id)
                  ELSE (SELECT Name + Suffix FROM tSQLt.Private_GetFullTypeName(user_type_id, max_length, precision, scale))
             END +
       ' ' + CASE WHEN is_identity = 1 AND @Identity = 1 
                  THEN (SELECT IdentityClause 
                          FROM tSQLt.Private_BuildIdentityClause(user_type_id, precision, @SchemaName + '.' + @NewNameOfOriginalTable))
                  ELSE '' 
             END + 
       ' ' + CASE WHEN is_computed = 1 AND @ComputedColumns = 1 
                  THEN ''
                  WHEN is_identity = 1 AND @Identity = 1 
                  THEN ''
                  ELSE 'NULL'
             END
      FROM sys.columns
     WHERE object_id = OBJECT_ID(@SchemaName + '.' + @NewNameOfOriginalTable)
     ORDER BY column_id
     FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');
    
   SELECT @Cmd = 'CREATE TABLE ' + @SchemaName + '.' + @TableName + '(' + STUFF(@Cols,1,1,'') + ')';
   
   EXEC (@Cmd);
END;
---Build-
GO
