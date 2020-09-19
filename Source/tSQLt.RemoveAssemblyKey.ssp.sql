IF OBJECT_ID('tSQLt.RemoveAssemblyKey') IS NOT NULL DROP PROCEDURE tSQLt.RemoveAssemblyKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.RemoveAssemblyKey
AS
BEGIN
  IF(NOT EXISTS(SELECT * FROM sys.fn_my_permissions(NULL,'server') AS FMP WHERE FMP.permission_name = 'CONTROL SERVER'))
  BEGIN
    RAISERROR('Only principals with CONTROL SERVER permission can execute this procedure.',16,10);
    RETURN -1;
  END;

  DECLARE @master_sys_sp_executesql NVARCHAR(MAX); SET @master_sys_sp_executesql = 'master.sys.sp_executesql';

  IF SUSER_ID('tSQLtAssemblyKey') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;
  EXEC @master_sys_sp_executesql N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtAssemblyKey'') DROP ASSEMBLY tSQLtAssemblyKey;';
END;
GO
---Build-
GO
