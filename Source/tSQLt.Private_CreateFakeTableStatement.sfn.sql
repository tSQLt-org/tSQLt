IF OBJECT_ID('tSQLt.Private_CreateFakeTableStatement') IS NOT NULL DROP FUNCTION tSQLt.Private_CreateFakeTableStatement;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_CreateFakeTableStatement(
  @OriginalTableObjectId INT,
  @FullFakeTableName NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT,
  @PreserveNOTNULL BIT
)
RETURNS TABLE
AS
RETURN
  SELECT 
      'CREATE TABLE ' + @FullFakeTableName + '(' + STUFF(Cols,1,1,'') + ')' CreateTableStatement,
      'CREATE TYPE ' + @FullFakeTableName + ' AS TABLE(' + STUFF(Cols,1,1,'') + ')' CreateTableTypeStatement
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
                ELSE CASE WHEN @PreserveNOTNULL = 1 AND c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END
           END
          FROM tSQLt.Private_SysColumns c
         CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(c.user_type_id, c.max_length, c.precision, c.scale, c.collation_name, c.object_id, c.column_id, @ComputedColumns) cc
         CROSS APPLY tSQLt.Private_GetDefaultConstraintDefinition(c.object_id, c.column_id, @Defaults) AS dc
         CROSS APPLY tSQLt.Private_GetIdentityDefinition(c.object_id, c.column_id, @Identity) AS id
         WHERE object_id = @OriginalTableObjectId
         ORDER BY column_id
         FOR XML PATH(''), TYPE
      ).value('.', 'NVARCHAR(MAX)')
    ) AS X(Cols);
GO
---Build-
GO
