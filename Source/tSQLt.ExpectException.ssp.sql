IF OBJECT_ID('tSQLt.ExpectException') IS NOT NULL DROP PROCEDURE tSQLt.ExpectException;
GO
---Build+
CREATE PROCEDURE tSQLt.ExpectException
@Message NVARCHAR(MAX) = NULL,
@Severity INT = NULL,
@State INT = NULL
AS
BEGIN
 INSERT INTO #ExpectException(ExpectedMessage, ExpectedSeverity, ExpectedState)
 VALUES(@Message, @Severity, @State);
END;
---Build-
GO
