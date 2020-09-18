IF OBJECT_ID('tSQLt.PrepareServer') IS NOT NULL DROP PROCEDURE tSQLt.PrepareServer;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.PrepareServer
AS
BEGIN
  EXEC tSQLt.Private_EnableCLR;
END;
GO
---Build-
GO
