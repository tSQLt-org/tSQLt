IF OBJECT_ID('tSQLt.AssertNotEquals') IS NOT NULL DROP PROCEDURE tSQLt.AssertNotEquals;
GO
---Build+
CREATE PROCEDURE tSQLt.AssertNotEquals
    @Expected SQL_VARIANT,
    @Actual SQL_VARIANT,
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
  IF @Expected = @Actual EXEC tSQLt.Fail;
      RETURN 0;
END;
---Build-
GO
