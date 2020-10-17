USE tSQLt_dev;
GO
DECLARE @cmd NVARCHAR(MAX);

IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)<14)
BEGIN
  PRINT '-------Dropping tSQLtAssemblyKey---------------';
  SET @cmd = N'IF SUSER_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql @cmd;
  SET @cmd = N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql @cmd;
END;
ELSE
BEGIN
  PRINT '-------Dropping of tSQLtAssemblyKey skipped---------------';
END;
GO
EXEC tSQLt.InstallAssemblyKey;
GO
EXECUTE AS LOGIN='tSQLt.Build.SA'
GO
EXEC tSQLt.Run 'EnableExternalAccessTests';
GO
REVERT
GO
