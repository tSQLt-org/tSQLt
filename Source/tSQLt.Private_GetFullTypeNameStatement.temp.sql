--TODO: MUST BE CHANGED LATER ON
IF OBJECT_ID('tSQLt.Private_GetFullTypeNameStatement') IS NOT NULL DROP FUNCTION tSQLt.Private_GetFullTypeNameStatement;
GO
CREATE FUNCTION tSQLt.Private_GetFullTypeNameStatement(@DatabaseName NVARCHAR(MAX),@TypeId NVARCHAR(MAX), @Length NVARCHAR(MAX), @Precision NVARCHAR(MAX), @Scale NVARCHAR(MAX), @CollationName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN 
SELECT '
SELECT X.SchemaName + ''.'' + X.Name + X.Suffix + X.Collation AS TypeName, X.SchemaName, X.Name, X.Suffix, X.is_table_type AS IsTableType
FROM(
  SELECT QUOTENAME(SCHEMA_NAME(T.schema_id)) SchemaName, QUOTENAME(T.name) Name,
              CASE WHEN T.max_length = -1
                    THEN ''''
                   WHEN '+@Length+' = -1
                    THEN ''(MAX)''
                   WHEN T.name LIKE ''n%char''
                    THEN ''('' + CAST('+@Length+' / 2 AS NVARCHAR) + '')''
                   WHEN T.name LIKE ''%char'' OR T.name LIKE ''%binary''
                    THEN ''('' + CAST('+@Length+' AS NVARCHAR) + '')''
                   WHEN T.name IN (''decimal'', ''numeric'')
                    THEN ''('' + CAST('+@Precision+' AS NVARCHAR) + '','' + CAST('+@Scale+' AS NVARCHAR) + '')''
                   WHEN T.name IN (''datetime2'', ''datetimeoffset'', ''time'')
                    THEN ''('' + CAST('+@Scale+' AS NVARCHAR) + '')''     
                   ELSE ''''
               END Suffix,
              CASE WHEN '+@CollationName+' IS NULL OR T.is_user_defined = 1 THEN ''''
                   ELSE '' COLLATE '' + '+@CollationName+'
		       END Collation,
               T.is_table_type
          FROM '+@DatabaseName+'.sys.types AS T WHERE T.user_type_id = '+@TypeId+'
)X
' cmd;
GO
