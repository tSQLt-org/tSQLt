IF OBJECT_ID('tSQLt.Private_MarkSchemaAsTestClass') IS NOT NULL DROP PROCEDURE tSQLt.Private_MarkSchemaAsTestClass;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_MarkSchemaAsTestClass
  @QuotedClassName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @UnquotedClassName NVARCHAR(MAX);

  SELECT @UnquotedClassName = name
    FROM sys.schemas
   WHERE QUOTENAME(name) = @QuotedClassName;

  EXEC sp_addextendedproperty @name = N'tSQLt.TestClass', 
                              @value = 1,
                              @level0type = 'SCHEMA',
                              @level0name = @UnquotedClassName;
END;
---Build-
GO
