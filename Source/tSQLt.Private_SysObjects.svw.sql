IF OBJECT_ID('tSQLt.Private_SysObjects') IS NOT NULL DROP VIEW tSQLt.Private_SysObjects;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysObjects AS SELECT * FROM sys.objects AS cc;
GO
---Build-
GO
