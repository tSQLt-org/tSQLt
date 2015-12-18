GO
IF SUSER_SID('tSQLt.Build') IS NULL
  CREATE LOGIN [tSQLt.Build] WITH PASSWORD = 0x010095EBA5D9A28749DF6ABFD4F5AAFBCE8BD839E0E35D6273B0 HASHED, CHECK_POLICY = OFF, DEFAULT_DATABASE = tempdb;
GO
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt.Build', @rolename = N'dbcreator'
GO
EXEC master.sys.sp_executesql N'GRANT EXTERNAL ACCESS ASSEMBLY TO [tSQLt.Build];';
GO
EXEC master.sys.sp_executesql N'IF USER_ID(''tSQLt.Build'') IS NOT NULL DROP USER [tSQLt.Build];';
EXEC master.sys.sp_executesql N'CREATE USER [tSQLt.Build] FROM LOGIN [tSQLt.Build];';
IF OBJECT_ID('master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke') IS NOT NULL EXEC master.sys.sp_executesql N'DROP PROCEDURE tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;';
EXEC master.sys.sp_executesql N'IF SCHEMA_ID(''tSQLt_testutil'') IS NOT NULL DROP SCHEMA tSQLt_testutil;';
EXEC master.sys.sp_executesql N'IF SCHEMA_ID(''tSQLt_testutil'') IS NULL EXEC(''CREATE SCHEMA tSQLt_testutil;'');';
EXEC master.sys.sp_executesql N'CREATE PROCEDURE tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke
AS
BEGIN
  REVOKE EXTERNAL ACCESS ASSEMBLY TO [tsqltKey];
END;';
EXEC master.sys.sp_executesql N'IF SUSER_ID(''tSQLt_testutil'') IS NOT NULL DROP LOGIN tSQLt_testutil;';
EXEC master.sys.sp_executesql N'IF CERT_ID(''tSQLt_testutil'') IS NOT NULL DROP CERTIFICATE tSQLt_testutil;';
EXEC master.sys.sp_executesql N'CREATE CERTIFICATE tSQLt_testutil ENCRYPTION BY PASSWORD = ''CE4E37C2-A9B6-409D-94C3-F051FB09D957DA704F07-2F5D-4C4A-8497-A9A10C6E51F4'' WITH SUBJECT=''tSQLt_testutil'';';
CREATE LOGIN tSQLt_testutil FROM CERTIFICATE tSQLt_testutil;
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt_testutil', @rolename = N'sysadmin';
EXEC master.sys.sp_executesql N'ADD SIGNATURE TO tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke BY CERTIFICATE tSQLt_testutil WITH PASSWORD = ''CE4E37C2-A9B6-409D-94C3-F051FB09D957DA704F07-2F5D-4C4A-8497-A9A10C6E51F4'';';
EXEC master.sys.sp_executesql N'GRANT EXECUTE ON OBJECT::tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke TO [tSQLt.Build];';
EXEC master.sys.sp_executesql N'ALTER CERTIFICATE tSQLt_testutil REMOVE PRIVATE KEY;';
GO
--SELECT SUSER_NAME(SP.grantee_principal_id),* FROM sys.server_permissions AS SP WHERE SP.grantor_principal_id = SUSER_ID('tSQLt.Build')
--EXEC master.sys.sp_executesql N'REVOKE IMPERSONATE ON LOGIN::[tSQLt.Build] FROM [MacWin7A\TeamCity];';