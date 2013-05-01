EXEC tSQLt.NewTestClass 'FailTests';
GO

CREATE PROCEDURE FailTests.[InvalidateTransaction]
AS
BEGIN
  BEGIN TRY
    DECLARE @i INT ;
    SET @i = 'NAN';
  END TRY
  BEGIN CATCH
  END CATCH;
END;
GO

CREATE PROC FailTests.[test Fail rolls back transaction if transaction is unable to be committed]
AS
BEGIN
  DECLARE @ErrorMessage NVARCHAR(MAX);
  SET @ErrorMessage = 'No Error Thrown';

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
  END CATCH;

  EXEC tSQLt.AssertEqualsString 'tSQLt.Failure', @ErrorMessage;
END;
GO

CREATE PROC FailTests.[test Fail does not change open tansaction count in case of XACT_STATE = -1]
AS
BEGIN
  DECLARE @ErrorMessage NVARCHAR(MAX);
  SET @ErrorMessage = 'No Error Thrown';

  BEGIN TRAN;

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
  END CATCH;
  
  COMMIT;

  EXEC tSQLt.AssertEqualsString 'tSQLt.Failure', @ErrorMessage;
END;
GO

CREATE PROC FailTests.[test Fail recreates savepoint if it has to clean up transactions]
AS
BEGIN
  DECLARE @TranName NVARCHAR(MAX);
  SELECT @TranName = TranName
    FROM tSQLt.TestResult
   WHERE Id = (SELECT MAX(Id) FROM tSQLt.TestResult);

  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
  END CATCH;

  BEGIN TRY
    ROLLBACK TRAN @TranName;
  END TRY
  BEGIN CATCH
    EXEC tSQLt.Fail 'Expected to be able to rollback the named transaction';
  END CATCH;
END;
GO

CREATE PROC FailTests.[test Fail gives info about cleanup work if transaction state is invalidated]
AS
BEGIN
  EXEC FailTests.InvalidateTransaction;

  BEGIN TRY
    EXEC tSQLt.Fail 'Not really a failure - just seeing that fail works';
  END TRY
  BEGIN CATCH
  END CATCH;

  DECLARE @TestResultMessage NVARCHAR(MAX);
  SELECT @TestResultMessage = Msg
    FROM tSQLt.TestMessage;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = '%Not really a failure - just seeing that fail works%'+CHAR(13)+CHAR(10)+'Warning: Uncommitable transaction detected!%'
  EXEC tSQLt.AssertLike @ExpectedMessage, @TestResultMessage;
END;
GO