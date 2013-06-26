IF OBJECT_ID('tSQLt.ExpectException') IS NOT NULL DROP PROCEDURE tSQLt.ExpectException;
GO
---Build+
CREATE PROCEDURE tSQLt.ExpectException
@ExpectedMessage NVARCHAR(MAX) = NULL,
@ExpectedSeverity INT = NULL,
@ExpectedState INT = NULL,
@Message NVARCHAR(MAX) = NULL,
@ExpectedMessagePattern NVARCHAR(MAX) = NULL
AS
BEGIN
 INSERT INTO #ExpectException(ExpectedMessage, ExpectedSeverity, ExpectedState, ExpectedMessagePattern, FailMessage)
 VALUES(@ExpectedMessage, @ExpectedSeverity, @ExpectedState, @ExpectedMessagePattern, @Message);
END;
---Build-
GO
