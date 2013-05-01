IF OBJECT_ID('tSQLt.Fail') IS NOT NULL DROP PROCEDURE tSQLt.Fail;
GO
---Build+
CREATE PROCEDURE tSQLt.Fail
    @Message0 NVARCHAR(MAX) = '',
    @Message1 NVARCHAR(MAX) = '',
    @Message2 NVARCHAR(MAX) = '',
    @Message3 NVARCHAR(MAX) = '',
    @Message4 NVARCHAR(MAX) = '',
    @Message5 NVARCHAR(MAX) = '',
    @Message6 NVARCHAR(MAX) = '',
    @Message7 NVARCHAR(MAX) = '',
    @Message8 NVARCHAR(MAX) = '',
    @Message9 NVARCHAR(MAX) = ''
AS
BEGIN
   DECLARE @WarningMessage NVARCHAR(MAX);
   SET @WarningMessage = '';

   IF XACT_STATE() = -1
   BEGIN
     SET @WarningMessage = CHAR(13)+CHAR(10)+'Warning: Uncommitable transaction detected!';

     DECLARE @TranName NVARCHAR(MAX);
     SELECT @TranName = TranName
       FROM tSQLt.TestResult
      WHERE Id = (SELECT MAX(Id) FROM tSQLt.TestResult);

     DECLARE @TranCount INT;
     SET @TranCount = @@TRANCOUNT;
     ROLLBACK;
     WHILE(@TranCount>0)
     BEGIN
       BEGIN TRAN;
       SET @TranCount = @TranCount -1;
     END;
     SAVE TRAN @TranName;
   END;

   INSERT INTO tSQLt.TestMessage(Msg)
   SELECT COALESCE(@Message0, '!NULL!')
        + COALESCE(@Message1, '!NULL!')
        + COALESCE(@Message2, '!NULL!')
        + COALESCE(@Message3, '!NULL!')
        + COALESCE(@Message4, '!NULL!')
        + COALESCE(@Message5, '!NULL!')
        + COALESCE(@Message6, '!NULL!')
        + COALESCE(@Message7, '!NULL!')
        + COALESCE(@Message8, '!NULL!')
        + COALESCE(@Message9, '!NULL!')
        + @WarningMessage;
        
   RAISERROR('tSQLt.Failure',16,10);
END;
---Build-
GO
