IF TYPE_ID('tSQLt.AssertStringTable') IS NOT NULL DROP TYPE tSQLt.AssertStringTable;
GO
---Built+
GO
CREATE TYPE tSQLt.AssertStringTable AS TABLE(value NVARCHAR(MAX));
GO
---Build-
GO
