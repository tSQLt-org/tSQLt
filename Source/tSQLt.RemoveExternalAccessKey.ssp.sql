IF OBJECT_ID('tSQLt.RemoveExternalAccessKey') IS NOT NULL DROP PROCEDURE tSQLt.RemoveExternalAccessKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.RemoveExternalAccessKey
AS
BEGIN
  IF(NOT EXISTS(SELECT * FROM sys.fn_my_permissions(NULL,'server') AS FMP WHERE FMP.permission_name = 'CONTROL SERVER'))
  BEGIN
    RAISERROR('Only principals with CONTROL SERVER permission can execute this procedure.',16,10);
    RETURN -1;
  END;

  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
END;
GO
---Build-
GO
