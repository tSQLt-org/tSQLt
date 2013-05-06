IF OBJECT_ID('tSQLt.Private_SqlVariantFormatter') IS NOT NULL DROP FUNCTION tSQLt.Private_SqlVariantFormatter;
GO
---Build+
CREATE FUNCTION tSQLt.Private_SqlVariantFormatter(@Value SQL_VARIANT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN CAST(@Value AS NVARCHAR(MAX));
END
---Build-
GO
