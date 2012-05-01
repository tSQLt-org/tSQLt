IF OBJECT_ID('tSQLt.Private_QuoteClassNameForNewTestClass') IS NOT NULL DROP FUNCTION tSQLt.Private_QuoteClassNameForNewTestClass;
GO
---Build+
CREATE FUNCTION tSQLt.Private_QuoteClassNameForNewTestClass(@ClassName NVARCHAR(MAX))
  RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN 
    CASE WHEN @ClassName LIKE '[[]%]' THEN @ClassName
         ELSE QUOTENAME(@ClassName)
     END;
END;
---Build-
GO
 