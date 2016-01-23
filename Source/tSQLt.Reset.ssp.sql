IF OBJECT_ID('tSQLt.Reset') IS NOT NULL DROP PROCEDURE tSQLt.Reset;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Reset
AS
BEGIN
  EXEC tSQLt.Private_ResetNewTestClassList;
END;
GO
---Build-
GO
