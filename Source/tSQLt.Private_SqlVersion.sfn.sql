IF OBJECT_ID('tSQLt.Private_SqlVersion') IS NOT NULL DROP FUNCTION tSQLt.Private_SqlVersion;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_SqlVersion()
RETURNS TABLE
AS
RETURN
  SELECT CAST(SERVERPROPERTY('ProductVersion')AS NVARCHAR(128)) ProductVersion,
		     CAST(SERVERPROPERTY('Edition')AS NVARCHAR(128)) Edition, 
		     host_platform HostPlatform 
    FROM sys.dm_os_host_info;
GO
---Build-
GO
