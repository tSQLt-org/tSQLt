IF OBJECT_ID('tSQLt.Private_CleanUpProcedureHandler') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUpProcedureHandler;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CleanUpProcedureHandler
  @CleanUpProcedureName NVARCHAR(MAX),
  @TestResult NVARCHAR(MAX) OUTPUT,
  @TestMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN
  BEGIN TRY
    EXEC @CleanUpProcedureName;
  END TRY
  BEGIN CATCH
    SET @TestResult = 'Error';
    SET @TestMsg = (CASE WHEN @TestMsg <> '' THEN @TestMsg + ' || ' ELSE '' END) + 'Error during clean up: (' + ERROR_MESSAGE() + ' | Procedure: ' + ISNULL(ERROR_PROCEDURE(),'<NULL>') + ' | Line: ' + CAST(ERROR_LINE() AS NVARCHAR(MAX)) + ' | Severity, State: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(MAX)) + ', ' + CAST(ERROR_STATE() AS NVARCHAR(MAX)) + ')';
  END CATCH;
END;
GO
