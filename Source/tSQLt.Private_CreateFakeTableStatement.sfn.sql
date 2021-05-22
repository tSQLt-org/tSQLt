IF OBJECT_ID('tSQLt.Private_CreateFakeTableStatement') IS NOT NULL DROP FUNCTION tSQLt.Private_CreateFakeTableStatement;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_CreateFakeTableStatement(
  @FullFakeTableName NVARCHAR(MAX),
  @OrigTableFullName NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT,
  @PreserveNOTNULL BIT
)
RETURNS TABLE
AS
RETURN
  SELECT 'CREATE TABLE ' + @FullFakeTableName + '(' + STUFF(Cols,1,1,'') + ')' CreateTableStatement
    FROM 
    (
      SELECT
      (
        SELECT
           ',' +
           QUOTENAME(name) + 
           cc.ColumnDefinition +
           dc.DefaultDefinition + 
           id.IdentityDefinition +
           CASE WHEN cc.IsComputedColumn = 1 OR id.IsIdentityColumn = 1 
                THEN ''
                ELSE ' NULL'
           END
          FROM sys.columns c
         CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(c.user_type_id, c.max_length, c.precision, c.scale, c.collation_name, c.object_id, c.column_id, @ComputedColumns, CASE WHEN @PreserveNOTNULL = 1 AND c.is_nullable = 0 THEN 1 ELSE 0 END) cc
         CROSS APPLY tSQLt.Private_GetDefaultConstraintDefinition(c.object_id, c.column_id, @Defaults) AS dc
         CROSS APPLY tSQLt.Private_GetIdentityDefinition(c.object_id, c.column_id, @Identity) AS id
         WHERE object_id = OBJECT_ID(@OrigTableFullName)
         ORDER BY column_id
         FOR XML PATH(''), TYPE
      ).value('.', 'NVARCHAR(MAX)')
    ) AS X(Cols);
GO
---Build-
GO
