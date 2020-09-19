  IF SUSER_ID('tSQLtAssemblyKey') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;

  DECLARE @cmd NVARCHAR(MAX);
  SET @cmd = N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql @cmd;
