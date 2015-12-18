IF OBJECT_ID('tSQLt.EnableExternalAccess') IS NOT NULL DROP PROCEDURE tSQLt.EnableExternalAccess;
GO
---Built+
GO
CREATE PROCEDURE tSQLt.EnableExternalAccess
  @try BIT = 0,
  @enable BIT = 1
AS
BEGIN
  BEGIN TRY
    IF @enable = 1
    BEGIN
      ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;
    END
    ELSE
    BEGIN
      ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
    END
  END TRY
  BEGIN CATCH
    DECLARE @Message NVARCHAR(4000);
    DECLARE @Severity INT;
    SET @Message = 'The attempt to ' +
                    CASE WHEN @enable = 1 THEN 'enable' ELSE 'disable' END +
                    ' tSQLt features requiring EXTERNAL_ACCESS failed';
    IF(@try = 1)
    BEGIN
      SELECT @Severity = 0, @Message = 'Warning: '+@Message+'.';
    END
    ELSE
    BEGIN
      SELECT @Severity = 16, @Message = @Message + ': '+ERROR_MESSAGE();
    END;
    RAISERROR(@Message,@Severity,10);
  END CATCH;

END;
GO
---Build-
GO
