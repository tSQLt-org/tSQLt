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
    IF(@try = 0)
    BEGIN
      DECLARE @Message NVARCHAR(4000);
      SET @Message = 'The attempt to ' +
                      CASE WHEN @enable = 1 THEN 'enable' ELSE 'disable' END +
                      ' tSQLt features requiring EXTERNAL_ACCESS failed' +
                      ': '+ERROR_MESSAGE();
      RAISERROR(@Message,16,10);
    END;
    RETURN -1;
  END CATCH;
  RETURN 0;
END;
GO
---Build-
GO
