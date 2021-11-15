EXEC tSQLt.NewTestClass 'Private_NoTransactionHandleTableTests';
GO
CREATE PROCEDURE Private_NoTransactionHandleTableTests.[test errors if Action is not an acceptable value]
AS
BEGIN
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid Action. @Action parameter must be one of the following: Save, Reset.', @ExpectedSeverity = 16, @ExpectedState = 10;

  EXEC tSQLt.Private_NoTransactionHandleTable @Action = 'Unexpected Action', @FullTableName = '[someschema].[sometable]', @TableAction = 'Restore';
END;
GO

/*--
TODO

- If TableAction is not Restore, throw an error.
- Save
-- TableAction = Restore
--- Saves an exact copy of the table into a tSQLt Temp Object table
--- Saves the name of the temp object table into a #temp table
--- tSQLt Temp Object is marked as IsTempObject = 1
- Reset
-- TableAction = Restore
--- Restores --> truncates original table and uses tSQLt Temp Object table to insert/restore data 

--*/