IF OBJECT_ID('tSQLt.RemoveExternalAccessKey') IS NOT NULL DROP PROCEDURE tSQLt.RemoveExternalAccessKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.RemoveExternalAccessKey
AS
BEGIN
  EXEC tSQLt.Private_Print @Message='tSQLt.RemoveExternalAccessKey is deprecated. Please use tSQLt.RemoveAssemblyKey instead.';
  EXEC tSQLt.RemoveAssemblyKey;
RETURN;
END;
GO
---Build-
GO
