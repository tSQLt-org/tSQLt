IF OBJECT_ID('tSQLt.Private_GetUniqueConstraintDefinition') IS NOT NULL DROP FUNCTION tSQLt.Private_GetUniqueConstraintDefinition;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetUniqueConstraintDefinition
(
    @ConstraintObjectId INT,
    @QuotedTableName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT 'ALTER TABLE '+
         @QuotedTableName +
         ' ADD CONSTRAINT ' +
         QUOTENAME(OBJECT_NAME(@ConstraintObjectId)) +
         ' ' +
         CASE WHEN KC.type_desc = 'UNIQUE_CONSTRAINT' 
              THEN 'UNIQUE'
              ELSE 'PRIMARY KEY'
           END +
         '(' +
         STUFF((
                 SELECT ','+QUOTENAME(C.name)
                   FROM sys.index_columns AS IC
                   JOIN sys.columns AS C
                     ON IC.object_id = C.object_id
                    AND IC.column_id = C.column_id
                  WHERE KC.unique_index_id = IC.index_id
                    AND KC.parent_object_id = IC.object_id
                    FOR XML PATH(''),TYPE
               ).value('.','NVARCHAR(MAX)'),
               1,
               1,
               ''
              ) +
         ');' AS CreateConstraintCmd,
         CASE WHEN KC.type_desc = 'UNIQUE_CONSTRAINT' 
              THEN ''
              ELSE (
                     SELECT 'ALTER TABLE ' +
                            @QuotedTableName +
                            ' ALTER COLUMN ' +
                            QUOTENAME(C.name)+
                            cc.ColumnDefinition +
                            ' NOT NULL;'
                       FROM sys.index_columns AS IC
                       JOIN sys.columns AS C
                         ON IC.object_id = C.object_id
                        AND IC.column_id = C.column_id
                      CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(C.user_type_id, C.max_length, C.precision, C.scale, C.collation_name, C.object_id, C.column_id, 0) cc
                      WHERE KC.unique_index_id = IC.index_id
                        AND KC.parent_object_id = IC.object_id
                        FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)')
           END AS NotNullColumnCmd
    FROM sys.key_constraints AS KC
   WHERE KC.object_id = @ConstraintObjectId;
GO
---Build-
