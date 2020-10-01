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
  
  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    SELECT @cmd = 
    '
      DECLARE @cmd NVARCHAR(MAX);
      SELECT @cmd = 
      (
        SELECT ''EXEC sys.sp_drop_trusted_assembly @hash = '' + CONVERT(NVARCHAR(MAX),TA.[hash],1) + '';'' FROM sys.trusted_assemblies AS TA
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
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyThumbPrint = @EAKey OUT;
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
  
  SELECT @KeyInfoPattern = '%publickeytoken='+LOWER(CONVERT(NVARCHAR(MAX),AK.thumbprint,2))+',%'
    FROM master.sys.asymmetric_keys AS AK 
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

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',PGEAKB.UnsignedEmptyBytes),1) + ', @description = N''tSQLt Ephemeral'';'
      FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS PGEAKB;
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         CONVERT(NVARCHAR(MAX),GUEB.UnsignedEmptyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB;
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

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    DECLARE @AssemblyKeyBytes VARBINARY(MAX);
    EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1) + ', @description = N''tSQLt Ephemeral'';';
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(NVARCHAR(MAX),@AssemblyKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;';
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

  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

  DECLARE @cmd NVARCHAR(MAX);

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1) + ', @description = N''tSQLt Ephemeral'';';
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(NVARCHAR(MAX),@AssemblyKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;';
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

  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

  DECLARE @cmd NVARCHAR(MAX);

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2019
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1) + ', @description = N''tSQLt Ephemeral'';';
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY [tSQLtAssemblyKey with wrong name!] AUTHORIZATION dbo FROM ' +
         CONVERT(NVARCHAR(MAX),@AssemblyKeyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;';
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
--[@tSQLt:MinSqlMajorVersion](14)
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
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InstallAssemblyKeyTests.[test works if trusted assembly entry exists already]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;
  
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 
         'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1) + ', @description = N''tSQLt Ephemeral'';';
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.ExpectNoException;  
  EXEC tSQLt.InstallAssemblyKey;

END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InstallAssemblyKeyTests.[test removes trusted assembly record when done]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;
  
  EXEC tSQLt.InstallAssemblyKey;

  SELECT * INTO #Actual FROM sys.trusted_assemblies AS TA WHERE TA.description = 'tSQLt Ephemeral';

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';

END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InstallAssemblyKeyTests.[test does not remove trusted assembly record if it already exists (based on hash)]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

  DECLARE @Hash NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);

  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 'EXEC sys.sp_add_trusted_assembly @hash = ' + @Hash + ', @description = N''some random description'';'
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallAssemblyKey;

  SELECT TA.hash, TA.description INTO #Actual FROM sys.trusted_assemblies AS TA;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(CONVERT(VARBINARY(64),@Hash,1), 'some random description'); --failing this on purpose. Fix me.
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InstallAssemblyKeyTests.[test removes trusted assembly record if it already exists (based on hash) and has the tSQLt Ephemeral description]
AS
BEGIN
  EXEC InstallAssemblyKeyTests.DropExistingItems;

  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

  DECLARE @Hash NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);

  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 'EXEC sys.sp_add_trusted_assembly @hash = ' + @Hash + ', @description = N''tSQLt Ephemeral'';'
  EXEC master.sys.sp_executesql @cmd;

  EXEC tSQLt.InstallAssemblyKey;

  SELECT * INTO #Actual FROM sys.trusted_assemblies AS TA WHERE TA.description = 'tSQLt Ephemeral';

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](13)
CREATE PROCEDURE InstallAssemblyKeyTests.[test grants EXTERNAL ACCESS ASSEMBLY permission to new login pre SQL 2017]
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
     AND SP.permission_name LIKE '%ASSEMBLY'

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES('SERVER','EXTERNAL ACCESS ASSEMBLY','GRANT');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InstallAssemblyKeyTests.[test grants UNSAFE ASSEMBLY permission to new login in SQL 2017 and later]
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
     AND SP.permission_name LIKE '%ASSEMBLY'

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES('SERVER','UNSAFE ASSEMBLY','GRANT');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO

CREATE PROCEDURE InstallAssemblyKeyTests.[test TODO]
AS
BEGIN
EXEC tSQLt.Fail 'TODO';
  -- change IAK to be able to run on 2017 and 2019 without setting clr strict security to 0
  
  --dropAssemblyKey: drop login, drop assymetric key, drop assembly, drop assembly if named differently, drop trusted_assembly exception
  --fix these ---v
  --[EnableExternalAccessTests].[test tSQLt.EnableExternalAccess produces no output, if @try = 1 and setting fails]
  --[Private_InitTests_EAKE].[test Private_Init does not fail if external access isn't possible]
  --[RemoveAssemblyKeyTests].[test removes tSQLtAssemblyKey assembly]
END;
GO
