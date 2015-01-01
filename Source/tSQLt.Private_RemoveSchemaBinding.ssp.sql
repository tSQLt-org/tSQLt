IF OBJECT_ID('tSQLt.Private_RemoveSchemaBinding') IS NOT NULL DROP PROCEDURE tSQLt.Private_RemoveSchemaBinding;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_RemoveSchemaBinding
  @object_id INT
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = tSQLt.[Private]::GetAlterStatementWithoutSchemaBinding(SM.definition)
    FROM sys.sql_modules AS SM
    JOIN 
    (
      SELECT DISTINCT SEDI.referencing_id,SEDI.referenced_id 
        FROM sys.sql_expression_dependencies AS SEDI
       WHERE SEDI.is_schema_bound_reference = 1
    ) AS SED 
      ON SED.referencing_id = SM.object_id
   WHERE SED.referenced_id = @object_id;
   EXEC(@cmd);
END;
GO
---Build-
