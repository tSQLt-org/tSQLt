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
  
  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=15)
  BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    SELECT @cmd = 
    '
      DECLARE @cmd NVARCHAR(MAX);
      SELECT @cmd = 
      (
        SELECT ''EXEC sys.sp_drop_trusted_assembly @hash = '' + BH.prefix + '';'' FROM sys.trusted_assemblies AS TA
         CROSS APPLY tSQLt.Private_Bin2Hex(TA.[hash]) AS BH
         WHERE TA.description = ''tSQLt Ephemeral''
           FOR XML PATH(''''),TYPE
      ).value(''.'',''NVARCHAR(MAX)'');
      EXEC(@cmd);
    ';
    EXEC(@cmd);
  END;
--SELECT * FROM sys.trusted_assemblies AS TA   
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

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if any assembly with the name tSQLtAssemblyKey already exists]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  EXEC tSQLt.InstallAssemblyKey;

  DECLARE @cmd NVARCHAR(MAX);

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=15)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + BH.prefix + ', @description = N''tSQLt Ephemeral'';'
      FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS PGEAKB
     CROSS APPLY tSQLt.Private_Bin2Hex(HASHBYTES('SHA2_512',PGEAKB.UnsignedEmptyBytes)) BH;
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB
   CROSS APPLY tSQLt.Private_Bin2Hex(GUEB.UnsignedEmptyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.ExpectNoException;  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test works if a tSQLtAssemblyKey assembly already exists under different name]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=15)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + BH.prefix + ', @description = N''tSQLt Ephemeral'';'
      FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
     CROSS APPLY tSQLt.Private_Bin2Hex(HASHBYTES('SHA2_512',PGEAKB.AssemblyKeyBytes)) BH;
  
    EXEC master.sys.sp_executesql @cmd;
  END;

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

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=15)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + BH.prefix + ', @description = N''tSQLt Ephemeral'';'
      FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
     CROSS APPLY tSQLt.Private_Bin2Hex(HASHBYTES('SHA2_512',PGEAKB.AssemblyKeyBytes)) BH;
  
    EXEC master.sys.sp_executesql @cmd;
  END;

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

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
---- run following tests with clr strict security = 1 ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
GO
--[@tsqlt:MinSQLMajorVersion](15)
CREATE PROCEDURE InstallAssemblyKeyTests.[test can install key even if clr strict security is set to 1]
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
--[@tsqlt:MinSQLMajorVersion](15)
CREATE PROCEDURE InstallAssemblyKeyTests.[test works if trusted assembly entry exists already]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 
         'EXEC sys.sp_add_trusted_assembly @hash = ' + BH.prefix + ', @description = N''tSQLt Ephemeral'';'
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(HASHBYTES('SHA2_512',PGEAKB.AssemblyKeyBytes)) BH;
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.ExpectNoException;  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO
--[@tsqlt:MinSQLMajorVersion](15)
CREATE PROCEDURE InstallAssemblyKeyTests.[test removes trusted assembly record when done]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  SELECT * INTO #Actual FROM sys.trusted_assemblies AS TA WHERE TA.description = 'tSQLt Ephemeral';

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';

END;
GO
--[@tsqlt:MinSQLMajorVersion](15)
CREATE PROCEDURE InstallAssemblyKeyTests.[test does not remove trusted assembly record when it pre-existed without the tSQLt Ephemeral description]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @Hash NVARCHAR(MAX);
  SELECT @Hash = BH.prefix
    FROM tSQLt.Private_GetAssemblyKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(HASHBYTES('SHA2_512',PGEAKB.AssemblyKeyBytes)) BH;

  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 'EXEC sys.sp_add_trusted_assembly @hash = ' + @Hash + ', @description = N''tSQLt Ephemeral'';'
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallAssemblyKey;

  SELECT TA.hash, TA.description INTO #Actual FROM sys.trusted_assemblies AS TA WHERE TA.hash = CAST(@Hash AS VARBINARY(MAX));

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(CAST(@Hash AS VARBINARY(MAX)), 'tSQLt Ephemeral');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InstallAssemblyKeyTests.[test TODO]
AS
BEGIN
EXEC tSQLt.Fail 'TODO';
  -- on 2019 add UNSAFE permission (maybe change to instead of add)
  -- change IEAK to be able to run on 2019 without altering server configurations (the bytes of the assembly can be used to create a bytecode over it, add it to the "whitelist" -use exception list- and then you can add it without having to worry about the configuration.)
  
  --InstallAssemblyKey: install exception record, install key assembly, create assymetric key, create login, grant permissions, drop assembly, drop exception
  --dropAssemblyKey: drop login, drop assymetric key, drop assembly, drop assembly if named differently, drop exception
END;
GO


  --IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=15)
  --BEGIN
  --  DECLARE @cmd NVARCHAR(MAX);
  --  SELECT @cmd = 
  --  '
  --    DECLARE @cmd NVARCHAR(MAX);
  --    SELECT @cmd = 
  --    (
  --      SELECT ''EXEC sys.sp_drop_trusted_assembly @hash = '' + BH.prefix + '';'' FROM sys.trusted_assemblies AS TA
  --       CROSS APPLY tSQLt.Private_Bin2Hex(TA.[hash]) AS BH
  --       WHERE TA.description = ''tSQLt Ephemeral''
  --         FOR XML PATH(''''),TYPE
  --    ).value(''.'',''NVARCHAR(MAX)'');
  --    EXEC(@cmd);
  --  ';
  --  EXEC(@cmd);
  --END;


--USE [master];
--GO
--DECLARE @AssemblyDescription NVARCHAR(4000) = N'tSQLtCLR, version=1.0.5873.27393, culture=neutral, publickeytoken=null, processorarchitecture=msil';
--DECLARE @AssemblyHash VARBINARY(256) = 0x3DB45B06CA8007DE7FEA05AB5F4A770293FCEF98640FECE939769652177E2A9B7CB6998EAE7BD3FC567ECDA62ADAE08AAA66094C9023F359127CAC8235550E37;
--IF NOT EXISTS (SELECT * FROM sys.trusted_assemblies WHERE [hash] = @AssemblyHash)
--BEGIN
--    EXECUTE sys.sp_add_trusted_assembly @hash = @AssemblyHash, @description = @AssemblyDescription;
--END
--EXECUTE sys.sp_drop_trusted_assembly @hash = @AssemblyHash
--GO

--SELECT * FROM sys.trusted_assemblies

/*

EXEC tSQLt.InstallAssemblyKey;
GO
EXEC sys.sp_configure @configname = 'clr strict security', @configvalue = 0;
GO
RECONFIGURE
GO
EXEC master.sys.sp_executesql N'GRANT UNSAFE ASSEMBLY TO tSQLtAssemblyKey;',N'';
GO
SELECT 
    HASHBYTES('SHA2_512',AssemblyKeyBytes),
    AssemblyKeyBytes, AssemblyKeyThumbPrint 
  FROM tSQLt.Private_GetAssemblyKeyBytes()

  

*/
