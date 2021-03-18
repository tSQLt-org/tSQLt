GO
---Build+
IF((SELECT SqlVersion FROM tSQLt.Info())>=14)
BEGIN
  EXEC('CREATE OR ALTER VIEW tSQLt.Private_HostPlatform AS SELECT host_platform FROM sys.dm_os_host_info;');
END;
---Build-
GO
