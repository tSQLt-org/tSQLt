EXEC master.sys.sp_executesql N'IF SCHEMA_ID(''tSQLt_testutil'') IS NULL EXEC(''CREATE SCHEMA tSQLt_testutil;'');';
EXEC master.sys.sp_executesql N'CREATE PROCEDURE tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke AS REVOKE EXTERNAL ACCESS ASSEMBLY TO [tSQLtExternalAccessKey];';
EXEC master.sys.sp_executesql N'CREATE CERTIFICATE tSQLt_testutil ENCRYPTION BY PASSWORD = ''CE4E37C2-A9B6-409D-94C3-F051FB09D957DA704F07-2F5D-4C4A-8497-A9A10C6E51F4'' WITH SUBJECT=''tSQLt_testutil'';';
CREATE LOGIN tSQLt_testutil FROM CERTIFICATE tSQLt_testutil;
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt_testutil', @rolename = N'sysadmin';
EXEC master.sys.sp_executesql N'ADD SIGNATURE TO tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke BY CERTIFICATE tSQLt_testutil WITH PASSWORD = ''CE4E37C2-A9B6-409D-94C3-F051FB09D957DA704F07-2F5D-4C4A-8497-A9A10C6E51F4'';';
EXEC master.sys.sp_executesql N'GRANT EXECUTE ON OBJECT::tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke TO [tSQLt.Build];';
EXEC master.sys.sp_executesql N'ALTER CERTIFICATE tSQLt_testutil REMOVE PRIVATE KEY;';
