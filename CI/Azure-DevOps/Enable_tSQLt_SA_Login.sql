USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
GO
USE [master]
GO
IF SUSER_ID('tSQLt_SA') IS NOT NULL DROP LOGIN tSQLt_SA;
GO
CREATE LOGIN [tSQLt_SA] WITH PASSWORD=N'qTv3f9gduUFuc8BQTZUq4MEcFbY3(2H)', DEFAULT_DATABASE=[tempdb], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
EXEC master..sp_addsrvrolemember @loginame = N'tSQLt_SA', @rolename = N'sysadmin'
GO
