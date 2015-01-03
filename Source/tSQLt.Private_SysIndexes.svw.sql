IF OBJECT_ID('tSQLt.Private_SysIndexes') IS NOT NULL DROP VIEW tSQLt.Private_SysIndexes;
GO
---Build+
IF((SELECT SqlVersion FROM tSQLt.Info())>9)
BEGIN
  EXEC('CREATE VIEW tSQLt.Private_SysIndexes AS SELECT * FROM sys.indexes;');
END
ELSE
BEGIN
  EXEC('CREATE VIEW tSQLt.Private_SysIndexes AS SELECT *,0 AS has_filter,'''' AS filter_definition FROM sys.indexes;');
END;
---Build-
GO