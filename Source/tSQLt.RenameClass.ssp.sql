IF OBJECT_ID('tSQLt.RenameClass') IS NOT NULL DROP PROCEDURE tSQLt.RenameClass;
GO
---Build+
CREATE PROCEDURE tSQLt.RenameClass
   @SchemaName SYSNAME,
   @NewSchemaName SYSNAME
AS
BEGIN
  DECLARE @MigrateObjectsCommand NVARCHAR(MAX);

  SELECT @NewSchemaName = PARSENAME(@NewSchemaName, 1),
         @SchemaName = PARSENAME(@SchemaName, 1);

  EXEC tSQLt.NewTestClass @NewSchemaName;

  SELECT @MigrateObjectsCommand = (
    SELECT Cmd AS [text()] FROM (
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.objects
     WHERE schema_id = SCHEMA_ID(@SchemaName)
       AND type NOT IN ('PK', 'F')
    UNION ALL 
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER XML SCHEMA COLLECTION::' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.xml_schema_collections
     WHERE schema_id = SCHEMA_ID(@SchemaName)
    UNION ALL 
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER TYPE::' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.types
     WHERE schema_id = SCHEMA_ID(@SchemaName)
    ) AS Cmds
       FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)');

  EXEC (@MigrateObjectsCommand);

  EXEC tSQLt.DropClass @SchemaName;
END;
---Build-
GO