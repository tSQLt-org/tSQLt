IF OBJECT_ID('tSQLt.Private_SysIdentityColumns') IS NOT NULL DROP VIEW tSQLt.Private_SysIdentityColumns;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysIdentityColumns AS SELECT * FROM sys.identity_columns AS cc;
GO
---Build-
GO
