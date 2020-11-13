IF OBJECT_ID('tSQLt.Private_SysDefaultConstraints') IS NOT NULL DROP VIEW tSQLt.Private_SysDefaultConstraints;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysDefaultConstraints AS SELECT * FROM sys.default_constraints AS cc;
GO
---Build-
GO
