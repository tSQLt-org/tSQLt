IF OBJECT_ID('tSQLt.ExpectNoException') IS NOT NULL DROP PROCEDURE tSQLt.ExpectNoException;
GO
---Build+
CREATE PROCEDURE tSQLt.ExpectNoException
  @Message NVARCHAR(MAX) = NULL
AS
BEGIN
 IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 0))
 BEGIN
   DELETE #ExpectException;
   RAISERROR('Each test can only contain one call to tSQLt.ExpectNoException.',16,10);
 END;
 IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
 BEGIN
   DELETE #ExpectException;
   RAISERROR('tSQLt.ExpectNoException cannot follow tSQLt.ExpectException inside a single test.',16,10);
 END;
 
 INSERT INTO #ExpectException(ExpectException, FailMessage)
 VALUES(0, @Message);
END;
---Build-
GO
