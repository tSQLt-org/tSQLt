IF OBJECT_ID('tSQLt.InstallExternalAccessKey') IS NOT NULL DROP PROCEDURE tSQLt.InstallExternalAccessKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.InstallExternalAccessKey
AS
BEGIN
  IF(NOT EXISTS(SELECT * FROM sys.fn_my_permissions(NULL,'server') AS FMP WHERE FMP.permission_name = 'CONTROL SERVER'))
  BEGIN
    RAISERROR('Only principals with CONTROL SERVER permission can execute this procedure.',16,10);
    RETURN -1;
  END;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @cmd2 NVARCHAR(MAX);
  DECLARE @master_sys_sp_executesql NVARCHAR(MAX); SET @master_sys_sp_executesql = 'master.sys.sp_executesql';

  SET @cmd = 'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ''DROP ASSEMBLY ''+QUOTENAME(A.name)+'';'''+ 
              '  FROM master.sys.assemblies AS A'+
              ' WHERE A.clr_name LIKE ''tsqltexternalaccesskey, %'';';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtExternalAccessKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.ExternalAccessKeyBytes) BH;
  EXEC @master_sys_sp_executesql @cmd;

  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;

  SET @cmd = N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ISNULL(''DROP LOGIN ''+QUOTENAME(SP.name)+'';'','''')+''DROP ASYMMETRIC KEY '' + QUOTENAME(AK.name) + '';'''+
              '  FROM master.sys.asymmetric_keys AS AK'+
              '  JOIN tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB'+
              '    ON AK.thumbprint = PGEAKB.ExternalAccessKeyThumbPrint'+
              '  LEFT JOIN master.sys.server_principals AS SP'+
              '    ON AK.sid = SP.sid;';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey FROM ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;
 
  SET @cmd = 'CREATE LOGIN tSQLtExternalAccessKey FROM ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'GRANT EXTERNAL ACCESS ASSEMBLY TO tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

END;
GO
---Build-
GO
