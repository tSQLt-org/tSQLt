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

  DECLARE @cmd NVARCHAR(MAX);
  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    DECLARE @TrustedHash NVARCHAR(MAX);
    DECLARE @AssemblyKeyBytes VARBINARY(MAX);
    EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;
    SELECT @TrustedHash = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);
    SELECT @cmd = 
           'IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash = ' + @TrustedHash +' AND description = ''tSQLt Ephemeral'')'+
           'EXEC sys.sp_drop_trusted_assembly @hash = ' + @TrustedHash + ';';
    EXEC master.sys.sp_executesql @cmd;
  END;


END;
GO
---Build-
GO
