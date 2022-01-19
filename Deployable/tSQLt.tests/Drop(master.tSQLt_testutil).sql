IF OBJECT_ID('master.tSQLt_testutil.tSQLtTestUtil_DropExternalAccessKey') IS NOT NULL EXEC master.sys.sp_executesql N'DROP PROCEDURE tSQLt_testutil.tSQLtTestUtil_DropExternalAccessKey;';
IF OBJECT_ID('master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke') IS NOT NULL EXEC master.sys.sp_executesql N'DROP PROCEDURE tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;';
EXEC master.sys.sp_executesql N'IF SCHEMA_ID(''tSQLt_testutil'') IS NOT NULL DROP SCHEMA tSQLt_testutil;';
EXEC master.sys.sp_executesql N'IF SUSER_ID(''tSQLt_testutil'') IS NOT NULL DROP LOGIN tSQLt_testutil;';
EXEC master.sys.sp_executesql N'IF CERT_ID(''tSQLt_testutil'') IS NOT NULL DROP CERTIFICATE tSQLt_testutil;';
