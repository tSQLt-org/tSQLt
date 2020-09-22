IF OBJECT_ID('tSQLt.Private_EnableCLR') IS NOT NULL DROP PROCEDURE tSQLt.Private_EnableCLR;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_EnableCLR
AS
BEGIN
  EXEC master.sys.sp_configure @configname='clr enabled', @configvalue = 1;
  RECONFIGURE;
END;
GO
---Build-
GO

