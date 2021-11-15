IF OBJECT_ID('tSQLt.Private_NoTransactionHandleTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_NoTransactionHandleTable;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_NoTransactionHandleTable
@FullTableName NVARCHAR(MAX),
@Action NVARCHAR(MAX)
AS
BEGIN
  RETURN;
END;
GO
