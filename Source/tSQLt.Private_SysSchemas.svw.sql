IF OBJECT_ID('tSQLt.Private_SysSchemas') IS NOT NULL DROP VIEW tSQLt.Private_SysSchemas;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysSchemas AS SELECT * FROM sys.schemas AS cc;
GO
---Build-
GO
