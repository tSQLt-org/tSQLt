IF OBJECT_ID('tSQLt.EnableExternalAccess') IS NOT NULL DROP PROCEDURE tSQLt.EnableExternalAccess;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.EnableExternalAccess
  @try BIT = 0,
  @enable BIT = 1
AS
BEGIN
  IF((SELECT HostPlatform FROM tSQLt.Info()) = 'Linux')
  BEGIN
    RAISERROR('The attempt to enable tSQLt features requiring EXTERNAL_ACCESS failed: EXTERNAL_ACCESS is not supported on Linux.',16,10);
  END;
  BEGIN TRY
    IF @enable = 1
    BEGIN
      EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;');
    END
    ELSE
    BEGIN
      EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;');
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
