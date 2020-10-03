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
  IF(DB_ID(@db_name)IS NOT NULL)
  BEGIN
    BEGIN TRY
    EXEC('
    USE master;
    ALTER DATABASE '+@db_name+' SET ONLINE WITH ROLLBACK IMMEDIATE;
    ALTER DATABASE '+@db_name+' SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
    USE '+@db_name+';
    ALTER DATABASE '+@db_name+' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    ');
    END TRY BEGIN CATCH END CATCH;
    EXEC('
    USE master;
    DROP DATABASE '+@db_name+';
    ');
  END;
END
GO
IF SUSER_SID('tSQLt.Build.SA') IS NOT NULL DROP LOGIN [tSQLt.Build.SA];
GO
IF SUSER_SID('tSQLt.Build') IS NOT NULL
BEGIN
  DECLARE @cmd NVARCHAR(MAX) =
    (
      SELECT 'EXEC #ForceDropDatabase '+QUOTENAME(D.name,'''')+';'
        FROM sys.databases AS D 
        JOIN sys.server_principals AS SP
          ON D.owner_sid = SP.sid
       WHERE SP.name = 'tSQLt.Build'
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);  

  DROP LOGIN [tSQLt.Build];
END;
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
