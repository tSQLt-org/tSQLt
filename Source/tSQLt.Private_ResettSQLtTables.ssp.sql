IF OBJECT_ID('tSQLt.Private_ResettSQLtTables') IS NOT NULL DROP PROCEDURE tSQLt.Private_ResettSQLtTables;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ResettSQLtTables
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = (
    SELECT 'EXEC tSQLt.Private_ResettSQLtTable @FullTableName = '''+X.Name+''', @Action = '''+X.Action+''';'
      FROM tSQLt.Private_ResettSQLtTableAction X
     WHERE X.Action = 'Restore'
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO