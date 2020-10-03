  GO
  EXEC #RemoveAssemblyKey;
  GO
  EXEC master.sys.sp_configure @configname='show advanced options', @configvalue = 1;
  GO
  RECONFIGURE;
  GO
  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14) EXEC master.sys.sp_configure @configname='clr strict security', @configvalue = 1;
  EXEC master.sys.sp_configure @configname='clr enabled', @configvalue = 0;
  GO
  RECONFIGURE;
  GO
  