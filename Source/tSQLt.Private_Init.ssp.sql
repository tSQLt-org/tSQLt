IF OBJECT_ID('tSQLt.Private_Init') IS NOT NULL DROP PROCEDURE tSQLt.Private_Init;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_Init
AS
BEGIN
  EXEC tSQLt.Private_CleanTestResult;
  EXEC tSQLt.Private_CleanTemporaryObject;

  DECLARE @enable BIT; SET @enable = 1;
  DECLARE @version_match BIT;SET @version_match = 0;
  BEGIN TRY
    EXEC sys.sp_executesql N'SELECT @r = CASE WHEN I.Version = I.ClrVersion THEN 1 ELSE 0 END FROM tSQLt.Info() AS I;',N'@r BIT OUTPUT',@version_match OUT;
  END TRY
  BEGIN CATCH
    RAISERROR('Cannot access CLR. Assembly might be in an invalid state. Try running EXEC tSQLt.EnableExternalAccess @enable = 0; or reinstalling tSQLt.',16,10);
    RETURN;
  END CATCH;
  IF(@version_match = 0)
  BEGIN
    RAISERROR('tSQLt is in an invalid state. Please reinstall tSQLt.',16,10);
    RETURN;
  END;

  IF((SELECT SqlEdition FROM tSQLt.Info()) <> 'SQL Azure')
  BEGIN
    EXEC tSQLt.EnableExternalAccess @enable = @enable, @try = 1;
  END;
END;
GO
---Build-
GO
