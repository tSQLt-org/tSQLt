IF OBJECT_ID('tSQLt.ExpectException') IS NOT NULL DROP PROCEDURE tSQLt.ExpectException;
GO
---Build+
CREATE PROCEDURE tSQLt.ExpectException
@ExpectedMessage NVARCHAR(MAX) = NULL,
@ExpectedSeverity INT = NULL,
@ExpectedState INT = NULL,
@Message NVARCHAR(MAX) = NULL,
@ExpectedMessagePattern NVARCHAR(MAX) = NULL,
@ExpectedErrorNumber INT = NULL
AS
BEGIN
 IF(EXISTS(SELECT 1 FROM #ExpectException))
 BEGIN
   RAISERROR('Each test can only contain one call to tSQLt.ExpectException or tSQLt.ExpectNoException.',16,10);
 END;
 
 INSERT INTO #ExpectException(ExpectException, ExpectedMessage, ExpectedSeverity, ExpectedState, ExpectedMessagePattern, ExpectedErrorNumber, FailMessage)
 VALUES(1, @ExpectedMessage, @ExpectedSeverity, @ExpectedState, @ExpectedMessagePattern, @ExpectedErrorNumber, @Message);
END;
---Build-
GO
