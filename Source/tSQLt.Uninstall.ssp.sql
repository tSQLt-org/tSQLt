IF OBJECT_ID('tSQLt.Uninstall') IS NOT NULL DROP PROCEDURE tSQLt.Uninstall;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Uninstall
AS
BEGIN

  EXEC tSQLt.DropClass @ClassName = 'tSQLt';  
  
  DROP ASSEMBLY tSQLtCLR;

  IF USER_ID('tSQLt.TestClass') IS NOT NULL DROP USER [tSQLt.TestClass];

END;
GO
---Build-
