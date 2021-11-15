IF OBJECT_ID('tSQLt.Private_NoTransactionHandleTables') IS NOT NULL DROP PROCEDURE tSQLt.Private_NoTransactionHandleTables;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_NoTransactionHandleTables
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = (
    SELECT 'EXEC tSQLt.Private_NoTransactionHandleTable @FullTableName = '''+X.Name+''', @Action = '''+X.Action+''';'
      FROM tSQLt.Private_NoTransactionTableAction X
     WHERE X.Action = 'Restore'
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO