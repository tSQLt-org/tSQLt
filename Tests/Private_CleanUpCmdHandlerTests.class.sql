EXEC tSQLt.NewTestClass 'Private_CleanUpCmdHandlerTests';
GO
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE FUNCTION Private_CleanUpCmdHandlerTests.[return 42134213 if correct error]()
RETURNS TABLE
AS
RETURN
  SELECT '9999' + ERROR_MESSAGE() FormattedError;
GO
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE FUNCTION Private_CleanUpCmdHandlerTests.[return 42424242+@NewMessage, @NewResult](
  @PrevMessage NVARCHAR(MAX),
  @PrevResult NVARCHAR(MAX),
  @NewMessage NVARCHAR(MAX),
  @NewResult NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT @PrevResult+':7777:'+@NewMessage Message, @NewResult Result
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_CleanUpCmdHandlerTests.[test is using the two error functions correctly]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_GetFormattedErrorInfo', @FakeFunctionName = 'Private_CleanUpCmdHandlerTests.[return 42134213 if correct error]';
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_HandleMessageAndResult', @FakeFunctionName = 'Private_CleanUpCmdHandlerTests.[return 42424242+@NewMessage, @NewResult]';

  DECLARE @TestResult NVARCHAR(MAX) = 'PrevResult';
  DECLARE @TestMessage NVARCHAR(MAX) = 'PrevMessage';
  EXEC tSQLt.Private_CleanUpCmdHandler @CleanUpCmd = 'RAISERROR(''ACleanUpError'',16,10);', @TestResult=@TestResult OUT, @TestMsg = @TestMessage OUT, @ResultInCaseOfError = 'NewResult';

  SELECT @TestMessage Message, @TestResult Result INTO #Actual;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('PrevResult:7777:Error during clean up: (9999ACleanUpError)','NewResult');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
