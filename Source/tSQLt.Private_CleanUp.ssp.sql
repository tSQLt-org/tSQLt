IF OBJECT_ID('tSQLt.Private_CleanUp') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUp;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CleanUp
  @FullTestName NVARCHAR(MAX),
  @ErrorMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

  EXEC tSQLt.UndoTestDoubles @Force = 0;

END;
GO
---Build-
GO
