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
   WHERE SM.object_id = @object_id;
   EXEC(@cmd);
END;
GO
---Build-
