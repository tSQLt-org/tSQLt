IF OBJECT_ID('tSQLt.Private_SysColumns') IS NOT NULL DROP VIEW tSQLt.Private_SysColumns;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysColumns AS SELECT * FROM sys.columns AS cc;
GO
---Build-
GO
