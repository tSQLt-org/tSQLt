IF TYPE_ID('tSQLt.AssertStringTable') IS NOT NULL DROP TYPE tSQLt.AssertStringTable;
GO
---Built+
GO
IF NOT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%')
BEGIN
  EXEC('CREATE TYPE tSQLt.AssertStringTable AS TABLE(value NVARCHAR(MAX));');
END;
GO
---Build-
GO
