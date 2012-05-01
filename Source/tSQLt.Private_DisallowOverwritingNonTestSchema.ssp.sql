IF OBJECT_ID('tSQLt.Private_DisallowOverwritingNonTestSchema') IS NOT NULL DROP PROCEDURE tSQLt.Private_DisallowOverwritingNonTestSchema;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_DisallowOverwritingNonTestSchema
  @ClassName NVARCHAR(MAX)
AS
BEGIN
  IF SCHEMA_ID(@ClassName) IS NOT NULL AND tSQLt.Private_IsTestClass(@ClassName) = 0
  BEGIN
    RAISERROR('Attempted to execute tSQLt.NewTestClass on ''%s'' which is an existing schema but not a test class', 16, 10, @ClassName);
  END
END;
---Build-
GO
