IF OBJECT_ID('tSQLt.Private_HostPlatform') IS NOT NULL DROP VIEW tSQLt.Private_HostPlatform;
GO
---Build+
CREATE VIEW tSQLt.Private_HostPlatform AS SELECT CAST('Windows' AS NVARCHAR(256)) AS host_platform;
---Build-
GO
