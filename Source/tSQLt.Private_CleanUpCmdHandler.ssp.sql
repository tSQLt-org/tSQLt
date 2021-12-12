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
    SET @TestMsg = (CASE WHEN @TestMsg <> '' THEN @TestMsg + ' [Result: '+ ISNULL(@TestResult,'<NULL>') + '] || ' ELSE '' END) + 'Error during clean up: (' + (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo())  + ')';
    SET @TestResult = @ResultInCaseOfError;
  END CATCH;
END;
GO
