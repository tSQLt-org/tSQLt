IF OBJECT_ID('tSQLt.Private_CleanUp') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUp;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CleanUp
  @FullTestName NVARCHAR(MAX),
  @Result NVARCHAR(MAX) OUTPUT,
  @ErrorMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN

  EXEC tSQLt.Private_CleanUpCmdHandler 
         @CleanUpCmd = 'EXEC tSQLt.Private_NoTransactionHandleTables @Action=''Reset'';',
         @TestResult = NULL,
         @TestMsg = @ErrorMsg OUT;

  EXEC tSQLt.Private_CleanUpCmdHandler 
         @CleanUpCmd = 'EXEC tSQLt.UndoTestDoubles @Force = 0;',
         @TestResult = @Result OUT,
         @TestMsg = @ErrorMsg OUT;

END;
GO
---Build-
GO
