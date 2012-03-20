IF OBJECT_ID('tSQLt.Private_GetForeignKeyDefinition') IS NOT NULL DROP FUNCTION tSQLt.Private_GetForeignKeyDefinition;
GO
---Build+
CREATE FUNCTION tSQLt.Private_GetForeignKeyDefinition(
    @SchemaName NVARCHAR(MAX),
    @ParentTableName NVARCHAR(MAX),
    @ForeignKeyName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN SELECT 'CONSTRAINT ' + name + ' FOREIGN KEY (' +
              parCol + ') REFERENCES ' + refName + '(' + refCol + ')' cmd,
              CASE 
                WHEN RefTableIsFakedInd = 1
                  THEN 'CREATE UNIQUE INDEX ' + tSQLt.Private::CreateUniqueObjectName() + ' ON ' + refName + '(' + refCol + ');' 
                ELSE '' 
              END CreIdxCmd
         FROM (SELECT QUOTENAME(SCHEMA_NAME(k.schema_id)) AS SchemaName,
                      QUOTENAME(k.name) AS name,
                      QUOTENAME(OBJECT_NAME(k.parent_object_id)) AS parName,
                      QUOTENAME(SCHEMA_NAME(refTab.schema_id)) + '.' + QUOTENAME(refTab.name) AS refName,
                      QUOTENAME(parCol.name) AS parCol,
                      QUOTENAME(refCol.name) AS refCol,
                      CASE WHEN e.name IS NULL THEN 0
                           ELSE 1 
                       END AS RefTableIsFakedInd
                 FROM sys.foreign_keys k
                 JOIN sys.foreign_key_columns c
                   ON k.object_id = c.constraint_object_id
                 JOIN sys.columns parCol
                   ON parCol.object_id = c.parent_object_id
                  AND parCol.column_id = c.parent_column_id
                 JOIN sys.columns refCol
                   ON refCol.object_id = c.referenced_object_id
                  AND refCol.column_id = c.referenced_column_id
                 LEFT JOIN sys.extended_properties e
                   ON e.name = 'tSQLt.FakeTable_OrgTableName'
                  AND e.value = OBJECT_NAME(c.referenced_object_id)
                 JOIN sys.tables refTab
                   ON COALESCE(e.major_id,refCol.object_id) = refTab.object_id
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName)
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName)
               )x;
---Build-