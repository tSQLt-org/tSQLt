GO
DECLARE @Counter INT = 0;
DECLARE @MaxAttempts INT = 10;
DECLARE @PreviousUser NVARCHAR(128) = SYSTEM_USER;

WHILE ORIGINAL_LOGIN() <> SYSTEM_USER AND @Counter < @MaxAttempts
BEGIN
    SET @Counter=@Counter+1;
    REVERT;
    SELECT @Counter=0,@PreviousUser=SYSTEM_USER WHERE @PreviousUser<>SYSTEM_USER;
    PRINT SYSTEM_USER
END

IF @Counter >= @MaxAttempts
BEGIN
    RAISERROR('WARNING: Impersonation could not be reverted after %d attempts.', 0, 1, @MaxAttempts) WITH NOWAIT;
END
GO