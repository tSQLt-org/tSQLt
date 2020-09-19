EXEC tSQLt.NewTestClass 'InstallAssemblyKeyTests';
GO
DECLARE @cmd NVARCHAR(MAX);
SET @cmd = 'IF(SUSER_ID(''InstallAssemblyKeyTestsUser1'')) IS NOT NULL DROP LOGIN InstallAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
SET @cmd = 'IF(SCHEMA_ID(''InstallAssemblyKeyTestsUser1'')) IS NOT NULL DROP SCHEMA InstallAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
SET @cmd = 'IF(USER_ID(''InstallAssemblyKeyTestsUser1'')) IS NOT NULL DROP USER InstallAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
GO
CREATE PROCEDURE InstallAssemblyKeyTests.DropExistingItems
AS
BEGIN
  IF SUSER_ID('tSQLtAssemblyKey') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtAssemblyKey'') DROP ASSEMBLY tSQLtAssemblyKey;';
END;
GO
CREATE PROCEDURE InstallAssemblyKeyTests.[test tSQLtAssemblyKey install data is signed with same key as tSQLt.clr]
AS
BEGIN
  DECLARE @EAKey VARBINARY(100);
  DECLARE @tSQLtKey VARBINARY(100);
  SELECT @EAKey = PGEAKB.AssemblyKeyThumbPrint
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB;
  SELECT @tSQLtKey = I.ClrSigningKey
    FROM tSQLt.Info() AS I;
  EXEC tSQLt.AssertEquals @Expected = @tSQLtKey, @Actual = @EAKey;
END;
GO
CREATE PROCEDURE InstallAssemblyKeyTests.[test creates correct certificate in master]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  DECLARE @KeyInfoPattern NVARCHAR(MAX);
  
  SELECT @KeyInfoPattern = '%publickeytoken='+BH.bare+',%'
    FROM master.sys.asymmetric_keys AS AK 
   CROSS APPLY tSQLt.Private_Bin2Hex(AK.thumbprint) AS BH
   WHERE AK.name = 'tSQLtAssemblyKey';


  DECLARE @tSQLtCLRInfo VARCHAR(MAX);
  SELECT @tSQLtCLRInfo = A.clr_name FROM sys.assemblies AS A WHERE name = 'tSQLtCLR';

  EXEC tSQLt.AssertLike @ExpectedPattern = @KeyInfoPattern, @Actual = @tSQLtCLRInfo;
END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey assembly already exists]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB
   CROSS APPLY tSQLt.Private_Bin2Hex(GUEB.UnsignedEmptyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey assembly already exists under different name]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.AssemblyKeyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test drops assembly when done]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  SELECT *
    INTO #Actual
    FROM master.sys.assemblies AS A
   WHERE A.name = 'tSQLtAssemblyKey'
      OR A.clr_name LIKE 'tsqltAssemblyKey, %';
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test creates login based on the new certificate]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  SELECT SP.name login_name,
         AK.name certificate_name,
         SP.type_desc 
    INTO #Actual
    FROM master.sys.server_principals AS SP
    JOIN master.sys.asymmetric_keys AS AK
      ON SP.sid = AK.sid
   WHERE SP.name = 'tSQLtAssemblyKey'
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  INSERT INTO #Expected
  VALUES('tSQLtAssemblyKey','tSQLtAssemblyKey','ASYMMETRIC_KEY_MAPPED_LOGIN');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey certificate already exists]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtAssemblyKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey certificate already exists under different name]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.AssemblyKeyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  SET @cmd = 'CREATE ASYMMETRIC KEY [tSQLtAssemblyKey->asymmetric key with wrong name!] FROM ASSEMBLY [tSQLtAssemblyKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY [tSQLtAssemblyKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey certificate/login pair already exists under different name]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.AssemblyKeyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  SET @cmd = 'CREATE ASYMMETRIC KEY [tSQLtAssemblyKey->asymmetric key with wrong name!] FROM ASSEMBLY [tSQLtAssemblyKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE LOGIN [tSQLtAssemblyKey->server principal with wrong name!] FROM ASYMMETRIC KEY [tSQLtAssemblyKey->asymmetric key with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY [tSQLtAssemblyKey with wrong name!];';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey login already exists]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE LOGIN tSQLtAssemblyKey WITH PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''',CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test grants EXTERNAL ACCESS ASSEMBLY permission to new login]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  SELECT SP.class_desc,
         SP.permission_name,
         SP.state_desc
    INTO #Actual
    FROM sys.server_permissions AS SP
   WHERE SP.grantee_principal_id = SUSER_ID('tSQLtAssemblyKey')
     AND SP.permission_name = 'EXTERNAL ACCESS ASSEMBLY'

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES('SERVER','EXTERNAL ACCESS ASSEMBLY','GRANT');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test non-sysadmin cannot execute procedure]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);
    
  SET @cmd = 'CREATE LOGIN InstallAssemblyKeyTestsUser1 WITH PASSWORD='''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE USER InstallAssemblyKeyTestsUser1;ALTER ROLE db_owner ADD MEMBER InstallAssemblyKeyTestsUser1;';
  IF((SELECT I.SqlVersion FROM tSQLt.Info() AS I) < 11)
  BEGIN
    SET @cmd = 'CREATE USER InstallAssemblyKeyTestsUser1;EXEC sys.sp_addrolemember @rolename = ''db_owner'', @membername = ''InstallAssemblyKeyTestsUser1'';';
  END
  EXEC master.sys.sp_executesql @cmd;
  EXEC sys.sp_executesql @cmd;
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Only principals with CONTROL SERVER permission can execute this procedure.';
  
  EXECUTE AS LOGIN = 'InstallAssemblyKeyTestsUser1';
  EXEC tSQLt.InstallAssemblyKey;
  REVERT;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test sysadmin can execute procedure]
AS
BEGIN

    EXEC InstallAssemblyKeyTests.DropExistingItems;

    DECLARE @cmd NVARCHAR(MAX);
    
    SET @cmd = 'CREATE LOGIN InstallAssemblyKeyTestsUser1 WITH PASSWORD='''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
    EXEC master.sys.sp_executesql @cmd;

    SET @cmd = 'GRANT CONTROL SERVER TO InstallAssemblyKeyTestsUser1;';
    EXEC master.sys.sp_executesql @cmd;
  
    EXEC tSQLt.ExpectNoException;
  
    EXECUTE AS LOGIN = 'InstallAssemblyKeyTestsUser1';
    EXEC tSQLt.InstallAssemblyKey;
    REVERT;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test tSQLt can be set to EXTERNAL ACCESS after InstallAssemblyKey executed]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  EXEC tSQLt.InstallAssemblyKey;

  EXEC tSQLt.ExpectNoException;

  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;  

END;
GO
