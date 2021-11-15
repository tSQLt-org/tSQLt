IF OBJECT_ID('tSQLt.Private_ResettSQLtTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_ResettSQLtTable;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ResettSQLtTable
@FullTableName NVARCHAR(MAX),
@Action NVARCHAR(MAX)
AS
BEGIN
  RETURN;
END;
GO
