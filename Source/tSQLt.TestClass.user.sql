---Build+
GO
IF (USER_ID('tSQLt.TestClass') IS NULL)
BEGIN
  CREATE USER [tSQLt.TestClass] WITHOUT LOGIN;
END;
GO
---Build-