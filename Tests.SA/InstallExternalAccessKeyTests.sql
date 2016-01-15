EXEC tSQLt.NewTestClass 'InstallExternalAccessKeyTests';
GO
CREATE PROCEDURE InstallExternalAccessKeyTests.DropExistingItems
AS
BEGIN
  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
END;
GO
CREATE PROCEDURE InstallExternalAccessKeyTests.[test InstallExternalAccessKey is signed with same key as tSQLt.clr]
AS
BEGIN
  DECLARE @EAKey VARBINARY(100);
  DECLARE @tSQLtKey VARBINARY(100);
  SELECT @EAKey = PGEAKB.ExternalAccessKeyThumbPrint
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB;
  SELECT @tSQLtKey = I.ClrSigningKey
    FROM tSQLt.Info() AS I;
  EXEC tSQLt.AssertEquals @Expected = @tSQLtKey, @Actual = @EAKey;
END;
GO
CREATE PROCEDURE InstallExternalAccessKeyTests.[test creates correct certificate in master]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallExternalAccessKey;

  DECLARE @KeyInfo VARCHAR(MAX);
  SELECT @KeyInfo = '%publickeytoken='+LOWER(CONVERT(VARCHAR(MAX),AK.thumbprint,2)) + ',%' 
    FROM master.sys.asymmetric_keys AS AK WHERE AK.name = 'tSQLtExternalAccessKey';

  DECLARE @tSQLtCLRInfo VARCHAR(MAX);
  SELECT @tSQLtCLRInfo = A.clr_name FROM sys.assemblies AS A WHERE name = 'tSQLtCLR';

  EXEC tSQLt.AssertLike @ExpectedPattern = @KeyInfo, @Actual = @tSQLtCLRInfo;
END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey assembly already exists]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtExternalAccessKey AUTHORIZATION dbo FROM ' +
         CONVERT(VARCHAR(MAX),GUEB.UnsignedEmptyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey assembly already exists under different name]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtExternalAccessKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(VARCHAR(MAX),PGEAKB.ExternalAccessKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test drops assembly when done]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallExternalAccessKey;

  SELECT *
    INTO #Actual
    FROM master.sys.assemblies AS A
   WHERE A.name = 'tSQLtExternalAccessKey'
      OR A.clr_name LIKE 'tsqltexternalaccesskey, %';
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test creates login based on the new certificate]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallExternalAccessKey;

  SELECT SP.name login_name,
         AK.name certificate_name,
         SP.type_desc 
    INTO #Actual
    FROM master.sys.server_principals AS SP
    JOIN master.sys.asymmetric_keys AS AK
      ON SP.sid = AK.sid
   WHERE SP.name = 'tSQLtExternalAccessKey'
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  INSERT INTO #Expected
  VALUES('tSQLtExternalAccessKey','tSQLtExternalAccessKey','ASYMMETRIC_KEY_MAPPED_LOGIN');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey certificate already exists]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+CAST(NEWID() AS NVARCHAR(MAX))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey certificate already exists under different name]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtExternalAccessKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(VARCHAR(MAX),PGEAKB.ExternalAccessKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB;
  EXEC master.sys.sp_executesql @cmd;
  
  SET @cmd = 'CREATE ASYMMETRIC KEY [tSQLtExternalAccessKey->asymmetric key with wrong name!] FROM ASSEMBLY [tSQLtExternalAccessKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY [tSQLtExternalAccessKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey certificate/login pair already exists under different name]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtExternalAccessKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(VARCHAR(MAX),PGEAKB.ExternalAccessKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB;
  EXEC master.sys.sp_executesql @cmd;
  
  SET @cmd = 'CREATE ASYMMETRIC KEY [tSQLtExternalAccessKey->asymmetric key with wrong name!] FROM ASSEMBLY [tSQLtExternalAccessKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE LOGIN [tSQLtExternalAccessKey->server principal with wrong name!] FROM ASYMMETRIC KEY [tSQLtExternalAccessKey->asymmetric key with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY [tSQLtExternalAccessKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test works if a tSQLtExternalAccessKey login already exists]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE LOGIN tSQLtExternalAccessKey WITH PASSWORD = '''+CAST(NEWID() AS NVARCHAR(MAX))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallExternalAccessKey;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test grants EXTERNAL ACCESS ASSEMBLY permission to new login]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallExternalAccessKey;

  SELECT SP.class_desc,
         SP.permission_name,
         SP.state_desc
    INTO #Actual
    FROM sys.server_permissions AS SP
   WHERE SP.grantee_principal_id = SUSER_ID('tSQLtExternalAccessKey')
     AND SP.permission_name = 'EXTERNAL ACCESS ASSEMBLY'

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES('SERVER','EXTERNAL ACCESS ASSEMBLY','GRANT');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test non-sysadmin cannot execute procedure]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);
    
  SET @cmd = 'CREATE LOGIN InstallExternalAccessKeyTestsUser1 WITH PASSWORD=''(*&^#@($&^%(&@#^$%(!&@'';';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE USER InstallExternalAccessKeyTestsUser1;ALTER ROLE db_owner ADD MEMBER InstallExternalAccessKeyTestsUser1;';
  EXEC master.sys.sp_executesql @cmd;
  EXEC sys.sp_executesql @cmd;

  SET @cmd = 'GRANT ALTER ANY LOGIN TO InstallExternalAccessKeyTestsUser1;';
  SET @cmd = 'GRANT EXTERNAL ACCESS ASSEMBLY TO InstallExternalAccessKeyTestsUser1 WITH GRANT OPTION;'+@cmd;
  EXEC master.sys.sp_executesql @cmd;

--  SET @cmd = 'ALTER SERVER ROLE securityadmin ADD MEMBER InstallExternalAccessKeyTestsUser1;';
--  EXEC master.sys.sp_executesql @cmd;


  EXEC tSQLt.ExpectException @ExpectedMessage = 'Only members of sysadmin can execute this procedure.';
  
  EXECUTE AS LOGIN = 'InstallExternalAccessKeyTestsUser1';
  EXEC tSQLt.InstallExternalAccessKey;
  REVERT;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test sysadmin can execute procedure]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);
    
  SET @cmd = 'CREATE LOGIN InstallExternalAccessKeyTestsUser1 WITH PASSWORD=''(*&^#@($&^%(&@#^$%(!&@'';';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'ALTER SERVER ROLE sysadmin ADD MEMBER InstallExternalAccessKeyTestsUser1;';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.ExpectNoException;
  
  EXECUTE AS LOGIN = 'InstallExternalAccessKeyTestsUser1';
  EXEC tSQLt.InstallExternalAccessKey;
  REVERT;

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test tSQLt can be set to EXTERNAL ACCESS after InstallExternalAccessKey executed]
AS
BEGIN
  EXEC InstallExternalAccessKeyTests.DropExistingItems;

  EXEC tSQLt.InstallExternalAccessKey;

  EXEC tSQLt.ExpectNoException;

  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;  

END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test include these tests in build]
AS
BEGIN

  EXEC tSQLt.Fail 'include these tests in build';
END;
GO


  --include 2 EA test cases in build

