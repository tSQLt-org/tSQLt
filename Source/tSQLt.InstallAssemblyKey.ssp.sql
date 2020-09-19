IF OBJECT_ID('tSQLt.InstallAssemblyKey') IS NOT NULL DROP PROCEDURE tSQLt.InstallAssemblyKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.InstallAssemblyKey
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

  SET @cmd = 'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtAssemblyKey'') DROP ASSEMBLY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ''DROP ASSEMBLY ''+QUOTENAME(A.name)+'';'''+ 
              '  FROM master.sys.assemblies AS A'+
              ' WHERE A.clr_name LIKE ''tsqltassemblykey, %'';';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.AssemblyKeyBytes) BH;
  EXEC @master_sys_sp_executesql @cmd;

  IF SUSER_ID('tSQLtAssemblyKey') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;

  SET @cmd = N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ISNULL(''DROP LOGIN ''+QUOTENAME(SP.name)+'';'','''')+''DROP ASYMMETRIC KEY '' + QUOTENAME(AK.name) + '';'''+
              '  FROM master.sys.asymmetric_keys AS AK'+
              '  JOIN tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB'+
              '    ON AK.thumbprint = PGEAKB.AssemblyKeyThumbPrint'+
              '  LEFT JOIN master.sys.server_principals AS SP'+
              '    ON AK.sid = SP.sid;';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'CREATE ASYMMETRIC KEY tSQLtAssemblyKey FROM ASSEMBLY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;
 
  SET @cmd = 'CREATE LOGIN tSQLtAssemblyKey FROM ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'GRANT EXTERNAL ACCESS ASSEMBLY TO tSQLtAssemblyKey;';
  EXEC @master_sys_sp_executesql @cmd;

END;
GO
---Build-
GO
