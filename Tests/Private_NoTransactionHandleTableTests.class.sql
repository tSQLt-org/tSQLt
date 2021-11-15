EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTableTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if Action is not an acceptable value]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid Action. @Action parameter must be one of the following: Save, Reset.', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Unexpected Action', @FullTableName = '[someschema].[sometable]', @TableAction = 'Restore';
END;
GO
