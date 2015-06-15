IF OBJECT_ID('tSQLt.SetVerbose') IS NOT NULL DROP PROCEDURE tSQLt.SetVerbose;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.SetVerbose
  @Verbose BIT = 1
AS
BEGIN
  EXEC tSQLt.Private_SetConfiguration @Name = 'Verbose', @Value = @Verbose;
END;
GO
---Build-
GO
