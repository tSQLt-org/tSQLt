IF OBJECT_ID('tSQLt.Private_GetDropItemCmd') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetDropItemCmd;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetDropItemCmd
(
/*SnipParamStart: CreateDropClassStatement.ps1*/
  @FullName NVARCHAR(MAX),
  @ItemType NVARCHAR(MAX)
/*SnipParamEnd: CreateDropClassStatement.ps1*/
)
RETURNS TABLE
AS
RETURN
/*SnipStart: CreateDropClassStatement.ps1*/
SELECT
    'DROP ' +
    CASE @ItemType 
      WHEN 'P' THEN 'PROCEDURE'
      WHEN 'PC' THEN 'PROCEDURE'
      WHEN 'U' THEN 'TABLE'
      WHEN 'IF' THEN 'FUNCTION'
      WHEN 'TF' THEN 'FUNCTION'
      WHEN 'FN' THEN 'FUNCTION'
      WHEN 'FT' THEN 'FUNCTION'
      WHEN 'V' THEN 'VIEW'
      WHEN 'type' THEN 'TYPE'
      WHEN 'xml_schema_collection' THEN 'XML SCHEMA COLLECTION'
      WHEN 'schema' THEN 'SCHEMA'
     END+
     ' ' + 
     @FullName + 
     ';' AS cmd
/*SnipEnd: CreateDropClassStatement.ps1*/
GO