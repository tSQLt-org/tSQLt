IF OBJECT_ID('tSQLt.Private_GetForeignKeyDefinition') IS NOT NULL DROP FUNCTION tSQLt.Private_GetForeignKeyDefinition;
IF OBJECT_ID('tSQLt.Private_GetForeignKeyRefColumns') IS NOT NULL DROP FUNCTION tSQLt.Private_GetForeignKeyRefColumns;
IF OBJECT_ID('tSQLt.Private_GetForeignKeyParColumns') IS NOT NULL DROP FUNCTION tSQLt.Private_GetForeignKeyParColumns;
GO
---Build+
CREATE FUNCTION tSQLt.Private_GetForeignKeyParColumns(
    @ConstraintObjectId INT
)
RETURNS TABLE
AS
RETURN SELECT STUFF((
                 SELECT ','+QUOTENAME(pci.name) FROM sys.foreign_key_columns c
                   JOIN sys.columns pci
                   ON pci.object_id = c.parent_object_id
                  AND pci.column_id = c.parent_column_id
                   WHERE @ConstraintObjectId = c.constraint_object_id
                   FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)'),1,1,'')  AS ColNames
GO

CREATE FUNCTION tSQLt.Private_GetForeignKeyRefColumns(
    @ConstraintObjectId INT
)
RETURNS TABLE
AS
RETURN SELECT STUFF((
                 SELECT ','+QUOTENAME(rci.name) FROM sys.foreign_key_columns c
                   JOIN sys.columns rci
                  ON rci.object_id = c.referenced_object_id
                  AND rci.column_id = c.referenced_column_id
                   WHERE @ConstraintObjectId = c.constraint_object_id
                   FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)'),1,1,'')  AS ColNames;
GO

CREATE FUNCTION tSQLt.Private_GetForeignKeyDefinition(
    @SchemaName NVARCHAR(MAX),
    @ParentTableName NVARCHAR(MAX),
    @ForeignKeyName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN SELECT 'CONSTRAINT ' + name + ' FOREIGN KEY (' +
              parCols + ') REFERENCES ' + refName + '(' + refCols + ')' cmd,
              CASE 
                WHEN RefTableIsFakedInd = 1
                  THEN 'CREATE UNIQUE INDEX ' + tSQLt.Private::CreateUniqueObjectName() + ' ON ' + refName + '(' + refCols + ');' 
                ELSE '' 
              END CreIdxCmd
         FROM (SELECT QUOTENAME(SCHEMA_NAME(k.schema_id)) AS SchemaName,
                      QUOTENAME(k.name) AS name,
                      QUOTENAME(OBJECT_NAME(k.parent_object_id)) AS parName,
                      QUOTENAME(SCHEMA_NAME(refTab.schema_id)) + '.' + QUOTENAME(refTab.name) AS refName,
                      parCol.ColNames AS parCols,
                      refCol.ColNames AS refCols,
                      CASE WHEN e.name IS NULL THEN 0
                           ELSE 1 
                       END AS RefTableIsFakedInd
                 FROM sys.foreign_keys k
                 CROSS APPLY tSQLt.Private_GetForeignKeyParColumns(k.object_id) AS parCol
                 CROSS APPLY tSQLt.Private_GetForeignKeyRefColumns(k.object_id) AS refCol
                 LEFT JOIN sys.extended_properties e
                   ON e.name = 'tSQLt.FakeTable_OrgTableName'
                  AND e.value = OBJECT_NAME(k.referenced_object_id)
                 JOIN sys.tables refTab
                   ON COALESCE(e.major_id,k.referenced_object_id) = refTab.object_id
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName)
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName)
               )x;
---Build-