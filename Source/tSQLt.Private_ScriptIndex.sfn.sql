IF OBJECT_ID('tSQLt.Private_ScriptIndex') IS NOT NULL DROP FUNCTION tSQLt.Private_ScriptIndex;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_ScriptIndex
(
  @object_id INT,
  @index_id INT
)
RETURNS TABLE
AS
RETURN
  SELECT I.index_id,
         I.name AS index_name,
         I.is_primary_key,
         I.is_unique,
         I.is_disabled,
         'CREATE ' +
         CASE WHEN I.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
         CASE I.type
           WHEN 1 THEN 'CLUSTERED'
           WHEN 2 THEN 'NONCLUSTERED'
           WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
           WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
           ELSE '{Index Type Not Supported!}' 
         END +
         ' INDEX ' +
         QUOTENAME(I.name)+
         ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + '.' + QUOTENAME(OBJECT_NAME(@object_id)) +
         CASE WHEN I.type NOT IN (5)
           THEN
             '('+ 
             CL.column_list +
             ')'
           ELSE ''
         END +
         CASE WHEN I.has_filter = 1
           THEN 'WHERE' + I.filter_definition
           ELSE ''
         END +
         CASE WHEN I.is_hypothetical = 1
           THEN 'WITH(STATISTICS_ONLY = -1)'
           ELSE ''
         END +
         ';' AS create_cmd
    FROM sys.indexes AS I
   CROSS APPLY
   (
     SELECT
      (
        SELECT 
          CASE WHEN OIC.rn > 1 THEN ',' ELSE '' END +
          CASE WHEN OIC.rn = 1 AND OIC.is_included_column = 1 AND I.type NOT IN (6) THEN ')INCLUDE(' ELSE '' END +
          QUOTENAME(OIC.name) +
          CASE WHEN OIC.is_included_column = 0
            THEN CASE WHEN OIC.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
            ELSE ''
          END
          FROM
          (
            SELECT C.name,
                   IC.is_descending_key, 
                   IC.key_ordinal,
                   IC.is_included_column,
                   ROW_NUMBER()OVER(PARTITION BY IC.is_included_column ORDER BY IC.key_ordinal, IC.index_column_id) AS rn
              FROM sys.index_columns AS IC
              JOIN sys.columns AS C
                ON IC.column_id = C.column_id
               AND IC.object_id = C.object_id
             WHERE IC.object_id = I.object_id
               AND IC.index_id = I.index_id
          )OIC
         ORDER BY OIC.is_included_column, OIC.rn
           FOR XML PATH(''),TYPE
      ).value('.','NVARCHAR(MAX)') AS column_list
   )CL
   WHERE I.object_id = @object_id
     AND I.index_id = ISNULL(@index_id,I.index_id);
GO
---Build-
GO
