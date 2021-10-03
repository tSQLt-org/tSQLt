IF OBJECT_ID('tSQLt.Private_SysComputedColumns') IS NOT NULL DROP VIEW tSQLt.Private_SysComputedColumns;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysComputedColumns AS SELECT * FROM sys.computed_columns AS cc;
GO
---Build-
GO
