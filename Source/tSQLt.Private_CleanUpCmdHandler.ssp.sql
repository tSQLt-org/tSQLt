IF OBJECT_ID('tSQLt.Private_CleanUpCmdHandler') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUpCmdHandler;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CleanUpCmdHandler
  @CleanUpCmd NVARCHAR(MAX),
  @TestResult NVARCHAR(MAX) OUTPUT,
  @TestMsg NVARCHAR(MAX) OUTPUT,
  @ResultInCaseOfError NVARCHAR(MAX) = 'Error'
AS
BEGIN
  BEGIN TRY
    EXEC(@CleanUpCmd);
  END TRY
  BEGIN CATCH
    DECLARE @NewMsg NVARCHAR(MAX) = 'Error during clean up: (' + (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo())  + ')';
    SELECT @TestMsg = Message, @TestResult = Result FROM tSQLt.Private_HandleMessageAndResult(@TestMsg /*PrevMsg*/, @TestResult /*PrevResult*/, @NewMsg /*NewMsg*/, @ResultInCaseOfError /*NewResult*/);
  END CATCH;
END;
GO
