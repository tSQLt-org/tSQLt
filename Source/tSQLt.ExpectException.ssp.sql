IF OBJECT_ID('tSQLt.ExpectException') IS NOT NULL DROP PROCEDURE tSQLt.ExpectException;
GO
---Build+
CREATE PROCEDURE tSQLt.ExpectException
@Message NVARCHAR(MAX) = NULL,
@Severity INT = NULL,
@State INT = NULL,
@MessagePattern NVARCHAR(MAX) = NULL
AS
BEGIN
 INSERT INTO #ExpectException(ExpectedMessage, ExpectedSeverity, ExpectedState, ExpectedMessagePattern)
 VALUES(@Message, @Severity, @State, @MessagePattern);
END;
---Build-
GO
