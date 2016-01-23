GO
IF SUSER_SID('tSQLt.Build') IS NULL
  CREATE LOGIN [tSQLt.Build] WITH PASSWORD = 0x010095EBA5D9A28749DF6ABFD4F5AAFBCE8BD839E0E35D6273B0 HASHED, CHECK_POLICY = OFF, DEFAULT_DATABASE = tempdb;
GO
IF SUSER_SID('tSQLt.Build.SA') IS NULL
  CREATE LOGIN [tSQLt.Build.SA] WITH PASSWORD = 0x010095EBA5D9A28749DF6ABFD4F5AAFBCE8BD839E0E35D6273B2 HASHED, CHECK_POLICY = OFF, DEFAULT_DATABASE = tempdb;
GO
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt.Build.SA', @rolename = N'sysadmin'
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt.Build', @rolename = N'dbcreator'
GO
--EXEC master.sys.sp_executesql N'GRANT EXTERNAL ACCESS ASSEMBLY TO [tSQLt.Build];';
GO
EXEC master.sys.sp_executesql N'IF USER_ID(''tSQLt.Build'') IS NOT NULL DROP USER [tSQLt.Build];';
EXEC master.sys.sp_executesql N'CREATE USER [tSQLt.Build] FROM LOGIN [tSQLt.Build];';
GO
--SELECT SUSER_NAME(SP.grantee_principal_id),* FROM sys.server_permissions AS SP WHERE SP.grantor_principal_id = SUSER_ID('tSQLt.Build')
--EXEC master.sys.sp_executesql N'REVOKE IMPERSONATE ON LOGIN::[tSQLt.Build] FROM [MacWin7A\TeamCity];';