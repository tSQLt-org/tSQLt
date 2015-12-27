EXEC tSQLt.NewTestClass 'InstallExternalAccessKeyTests';
GO
CREATE PROCEDURE InstallExternalAccessKeyTests.[test InstallExternalAccessKey creates correct certificate in master]
AS
BEGIN
  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  
  EXEC tSQLt.InstallExternalAccessKey;

  DECLARE @KeyInfo VARCHAR(MAX);
  SELECT @KeyInfo = '%publickeytoken='+CONVERT(VARCHAR(MAX),AK.thumbprint,2) + ',%' 
    FROM master.sys.asymmetric_keys AS AK WHERE AK.name = 'tSQLtExternalAccessKey';

  DECLARE @tSQLtCLRInfo VARCHAR(MAX);
  SELECT @tSQLtCLRInfo = A.clr_name FROM sys.assemblies AS A WHERE name = 'tSQLtCLR';

  EXEC tSQLt.AssertLike @ExpectedPattern = @KeyInfo, @Actual = @tSQLtCLRInfo;
END;
GO


  --test InstallExternalAccessKey
  --include 2 EA test cases in build

