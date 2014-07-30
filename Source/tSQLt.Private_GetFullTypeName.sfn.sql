IF OBJECT_ID('tSQLt.Private_GetFullTypeName') IS NOT NULL DROP FUNCTION tSQLt.Private_GetFullTypeName;
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN SELECT SchemaName + '.' + Name + Suffix + Collation AS TypeName, SchemaName, Name, Suffix
FROM(
  SELECT QUOTENAME(SCHEMA_NAME(T.schema_id)) SchemaName, QUOTENAME(T.name) Name,
              CASE WHEN T.max_length = -1
                    THEN ''
                   WHEN @Length = -1
                    THEN '(MAX)'
                   WHEN T.name LIKE 'n%char'
                    THEN '(' + CAST(@Length / 2 AS NVARCHAR) + ')'
                   WHEN T.name LIKE '%char' OR T.name LIKE '%binary'
                    THEN '(' + CAST(@Length AS NVARCHAR) + ')'
                   WHEN T.name IN ('decimal', 'numeric')
                    THEN '(' + CAST(@Precision AS NVARCHAR) + ',' + CAST(@Scale AS NVARCHAR) + ')'
                   ELSE ''
               END Suffix,
              CASE WHEN @CollationName IS NULL OR T.is_user_defined = 1 THEN ''
                   ELSE ' COLLATE ' + @CollationName
               END Collation
          FROM sys.types AS T WHERE T.user_type_id = @TypeId
          )X;
---Build-
GO
