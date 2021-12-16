IF OBJECT_ID('tSQLt.Private_AssertNoSideEffects') IS NOT NULL DROP PROCEDURE tSQLt.Private_AssertNoSideEffects;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_AssertNoSideEffects
  @BeforeExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @AfterExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @TestResult NVARCHAR(MAX) OUTPUT,
  @TestMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN
  DECLARE @Command NVARCHAR(MAX) = (SELECT Command FROM tSQLt.Private_AssertNoSideEffects_GenerateCommand(@BeforeExecutionObjectSnapshotTableName, @AfterExecutionObjectSnapshotTableName));
  EXEC tSQLt.Private_CleanUpCmdHandler @CleanUpCmd=@Command, @TestResult=@TestResult OUT, @TestMsg=@TestMsg OUT;
END;
GO
