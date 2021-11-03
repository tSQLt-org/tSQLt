IF OBJECT_ID('tSQLt.DropClass') IS NOT NULL DROP PROCEDURE tSQLt.DropClass;
GO
---Build+
CREATE PROCEDURE tSQLt.DropClass
    @ClassName NVARCHAR(MAX)
AS
BEGIN
/*SnipStart: CreateDropClassStatement.ps1*/
    DECLARE @Cmd NVARCHAR(MAX);

    WITH ObjectInfo(FullName, ItemType) AS
         (
           SELECT 
               QUOTENAME(SCHEMA_NAME(O.schema_id))+'.'+QUOTENAME(O.name),
               O.type
             FROM sys.objects AS O
            WHERE O.schema_id = SCHEMA_ID(@ClassName)
         ),
         TypeInfo(FullName, ItemType) AS
         (
           SELECT 
               QUOTENAME(SCHEMA_NAME(T.schema_id))+'.'+QUOTENAME(T.name),
               'type'
             FROM sys.types AS T
            WHERE T.schema_id = SCHEMA_ID(@ClassName)
         ),
         XMLSchemaInfo(FullName, ItemType) AS
         (
           SELECT 
               QUOTENAME(SCHEMA_NAME(XSC.schema_id))+'.'+QUOTENAME(XSC.name),
               'xml_schema_collection'
             FROM sys.xml_schema_collections AS XSC
            WHERE XSC.schema_id = SCHEMA_ID(@ClassName)
         ),
         SchemaInfo(FullName, ItemType) AS
         (
           SELECT 
               QUOTENAME(S.name),
               'schema'
             FROM sys.schemas AS S
            WHERE S.schema_id = SCHEMA_ID(PARSENAME(@ClassName,1))
         ),
         DropStatements(no,FullName,ItemType) AS
         (
           SELECT 10, FullName, ItemType
              FROM ObjectInfo
             UNION ALL
           SELECT 20, FullName, ItemType
              FROM TypeInfo
             UNION ALL
           SELECT 30, FullName, ItemType
              FROM XMLSchemaInfo
             UNION ALL
            SELECT 10000, FullName, ItemType
              FROM SchemaInfo
         ),
         StatementBlob(xml)AS
         (
           SELECT GDIC.cmd [text()]
             FROM DropStatements DS
            CROSS APPLY tSQLt.Private_GetDropItemCmd(DS.FullName, DS.ItemType) GDIC
            ORDER BY no
              FOR XML PATH(''), TYPE
         )
    SELECT @Cmd = xml.value('/', 'NVARCHAR(MAX)') 
      FROM StatementBlob;

    EXEC(@Cmd);
END;
/*SnipEnd: CreateDropClassStatement.ps1*/
---Build-
GO
