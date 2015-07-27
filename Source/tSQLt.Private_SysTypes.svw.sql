IF OBJECT_ID('tSQLt.Private_SysTypes') IS NOT NULL DROP VIEW tSQLt.Private_SysTypes;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_SysTypes AS SELECT * FROM sys.types AS T;
GO
IF(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%')
BEGIN
  EXEC('ALTER VIEW tSQLt.Private_SysTypes AS SELECT *,0 is_table_type FROM sys.types AS T;');
END;
GO
---Build-
GO
