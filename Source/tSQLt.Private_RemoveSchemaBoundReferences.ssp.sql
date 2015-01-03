IF OBJECT_ID('tSQLt.Private_RemoveSchemaBoundReferences') IS NOT NULL DROP PROCEDURE tSQLt.Private_RemoveSchemaBoundReferences;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_RemoveSchemaBoundReferences
  @object_id INT
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 
  (
    SELECT 
      'EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = '+STR(SED.referencing_id)+';'+
      'EXEC tSQLt.Private_RemoveSchemaBinding @object_id = '+STR(SED.referencing_id)+';'
      FROM
      (
        SELECT DISTINCT SEDI.referencing_id,SEDI.referenced_id 
          FROM sys.sql_expression_dependencies AS SEDI
         WHERE SEDI.is_schema_bound_reference = 1
      ) AS SED 
     WHERE SED.referenced_id = @object_id
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO
---Build-
GO
