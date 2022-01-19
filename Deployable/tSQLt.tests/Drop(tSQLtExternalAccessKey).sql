  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;

  DECLARE @cmd NVARCHAR(MAX);
  SET @cmd = N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;
