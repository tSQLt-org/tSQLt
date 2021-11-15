IF OBJECT_ID('tSQLt.Private_CleanUp') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUp;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CleanUp
  @FullTestName NVARCHAR(MAX),
  @ErrorMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN
  EXEC tSQLt.UndoTestDoubles @Force = 0;
  EXEC tSQLt.Private_NoTransactionHandleTables;
END;
GO
---Build-
GO
