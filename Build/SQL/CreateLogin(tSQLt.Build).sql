GO
SET NOCOUNT ON;
GO
USE master;
GO
IF OBJECT_ID('tempdb..#ForceDropDatabase') IS NOT NULL DROP PROCEDURE #ForceDropDatabase;
GO
CREATE PROCEDURE #ForceDropDatabase
@db_name NVARCHAR(MAX)
AS
BEGIN
  SET @db_name = PARSENAME(@db_name,1);
  DECLARE @cmd NVARCHAR(MAX);
  IF(DB_ID(@db_name)IS NOT NULL)
  BEGIN
    BEGIN TRY
    SET @cmd = '
    USE master;
    ALTER DATABASE '+QUOTENAME(@db_name)+' SET ONLINE WITH ROLLBACK IMMEDIATE;
    ALTER DATABASE '+QUOTENAME(@db_name)+' SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
    USE '+QUOTENAME(@db_name)+';
    ALTER DATABASE '+QUOTENAME(@db_name)+' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    ';
    EXEC(@cmd);
    END TRY BEGIN CATCH END CATCH;
    SET @cmd = '
    USE master;
    DROP DATABASE '+QUOTENAME(@db_name)+';
    ';
    EXEC(@cmd);
  END;
END
GO
IF OBJECT_ID('tempdb..#ForceDropLogin') IS NOT NULL DROP PROCEDURE #ForceDropLogin;
GO
CREATE PROCEDURE #ForceDropLogin
@login_name NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd_dd NVARCHAR(MAX) =
    (
      SELECT 'EXEC #ForceDropDatabase '+QUOTENAME(D.name,'''')+';'
        FROM sys.databases AS D 
        JOIN sys.server_principals AS SP
          ON D.owner_sid = SP.sid
       WHERE SP.name = @login_name
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd_dd);  
  DECLARE @cmd_dl NVARCHAR(MAX) = (
  SELECT 'KILL '+CAST(session_id AS NVARCHAR(MAX))+';' 
    FROM sys.dm_exec_sessions WHERE login_name = @login_name
    FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)')
  EXEC(@cmd_dl);
  IF SUSER_SID('tSQLt.Build.SA') IS NOT NULL 
  BEGIN
    SET @cmd_dl = 'DROP LOGIN '+QUOTENAME(@login_name)+';'
    EXEC(@cmd_dl);
  END
END
GO
EXEC #ForceDropLogin 'tSQLt.Build';
GO
EXEC #ForceDropLogin 'tSQLt.Build.SA';
GO
CREATE LOGIN [tSQLt.Build] WITH PASSWORD = 0x010095EBA5D9A28749DF6ABFD4F5AAFBCE8BD839E0E35D6273B0 HASHED, CHECK_POLICY = OFF, DEFAULT_DATABASE = tempdb;
GO
CREATE LOGIN [tSQLt.Build.SA] WITH PASSWORD = 0x010095EBA5D9A28749DF6ABFD4F5AAFBCE8BD839E0E35D6273B2 HASHED, CHECK_POLICY = OFF, DEFAULT_DATABASE = tempdb;
GO
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt.Build.SA', @rolename = N'sysadmin'
EXEC sys.sp_addsrvrolemember @loginame = N'tSQLt.Build', @rolename = N'dbcreator'
GO
EXEC master.sys.sp_executesql N'IF USER_ID(''tSQLt.Build'') IS NOT NULL DROP USER [tSQLt.Build];';
EXEC master.sys.sp_executesql N'CREATE USER [tSQLt.Build] FROM LOGIN [tSQLt.Build];';
GO
