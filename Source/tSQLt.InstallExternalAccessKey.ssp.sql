IF OBJECT_ID('tSQLt.InstallExternalAccessKey') IS NOT NULL DROP PROCEDURE tSQLt.InstallExternalAccessKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.InstallExternalAccessKey
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = 'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;

  SELECT @cmd = 'DROP ASSEMBLY '+QUOTENAME(A.name)+';' 
    FROM master.sys.assemblies AS A 
   WHERE A.clr_name LIKE 'tsqltexternalaccesskey, %';
  EXEC master.sys.sp_executesql @cmd;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtExternalAccessKey AUTHORIZATION dbo FROM ' +
         CONVERT(VARCHAR(MAX),PGEAKB.ExternalAccessKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB;
  EXEC master.sys.sp_executesql @cmd;

  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;

  SET @cmd = N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;

  SELECT @cmd = ISNULL('DROP LOGIN '+QUOTENAME(SP.name)+';','')+'DROP ASYMMETRIC KEY ' + QUOTENAME(AK.name) + ';'
    FROM master.sys.asymmetric_keys AS AK
    JOIN tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB
      ON AK.thumbprint = PGEAKB.ExternalAccessKeyThumbPrint
    LEFT JOIN master.sys.server_principals AS SP
      ON AK.sid = SP.sid
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey FROM ASSEMBLY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;
 
  SET @cmd = 'CREATE LOGIN tSQLtExternalAccessKey FROM ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;

END;
GO
---Build-
GO
