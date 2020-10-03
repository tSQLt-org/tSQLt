EXEC tSQLt.NewTestClass 'RemoveAssemblyKeyTests';
GO
DECLARE @cmd NVARCHAR(MAX);
SET @cmd = 'IF(SUSER_ID(''RemoveAssemblyKeyTestsUser1'')) IS NOT NULL DROP LOGIN RemoveAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
SET @cmd = 'IF(SCHEMA_ID(''RemoveAssemblyKeyTestsUser1'')) IS NOT NULL DROP SCHEMA RemoveAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
SET @cmd = 'IF(USER_ID(''RemoveAssemblyKeyTestsUser1'')) IS NOT NULL DROP USER RemoveAssemblyKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
GO
CREATE PROCEDURE RemoveAssemblyKeyTests.DropExistingItems
AS
BEGIN
  IF SUSER_ID('tSQLtAssemblyKey') IS NOT NULL DROP LOGIN tSQLtAssemblyKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtAssemblyKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtAssemblyKey'') DROP ASSEMBLY tSQLtAssemblyKey;';
  DECLARE @cmd NVARCHAR(MAX);
  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_drop_trusted_assembly is new (and required) in 2017
    DECLARE @TrustedHash NVARCHAR(MAX);
    SELECT @TrustedHash = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',PGEAKB.UnsignedEmptyBytes),1)
      FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS PGEAKB

    SELECT @cmd = 
           'IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash = ' + @TrustedHash +')'+
           'EXEC sys.sp_drop_trusted_assembly @hash = ' + @TrustedHash + ';';
    EXEC master.sys.sp_executesql @cmd;

    DECLARE @AssemblyKeyBytes VARBINARY(MAX);
    EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;

    SELECT @TrustedHash = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);

    SELECT @cmd = 
           'IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash = ' + @TrustedHash +')'+
           'EXEC sys.sp_drop_trusted_assembly @hash = ' + @TrustedHash + ';';
    EXEC master.sys.sp_executesql @cmd;
  END;
END;
GO
GO
CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey assembly]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  IF(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT)>=14)
  BEGIN
    -- sp_add_trusted_assembly is new (and required) in 2017
    SELECT @cmd = 
           'EXEC sys.sp_add_trusted_assembly @hash = ' + CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',PGEAKB.UnsignedEmptyBytes),1) + ', @description = N''tSQLt Ephemeral'';'
      FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS PGEAKB
     WHERE NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies AS TA WHERE TA.hash = HASHBYTES('SHA2_512',PGEAKB.UnsignedEmptyBytes));
  
    EXEC master.sys.sp_executesql @cmd;
  END;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         CONVERT(NVARCHAR(MAX),GUEB.UnsignedEmptyBytes,1) +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  IF(EXISTS(SELECT 1 FROM master.sys.assemblies WHERE name = 'tSQLtAssemblyKey'))
  BEGIN
    EXEC tSQLt.Fail 'Assembly tSQLtAssemblyKey not removed.';
  END;
END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey asymmetric key]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtAssemblyKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  SELECT *
    INTO #Actual
    FROM master.sys.asymmetric_keys AS AK
   WHERE AK.name = 'tSQLtAssemblyKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual'; --<-- this might blow up if the table isn't empty.
END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey login]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE LOGIN tSQLtAssemblyKey WITH PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''',CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  SELECT *
    INTO #Actual
    FROM master.sys.server_principals AS SP
   WHERE SP.name = 'tSQLtAssemblyKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual'; --<-- this might blow up if the table isn't empty.
END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey asymmetric key and login in correct order]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtAssemblyKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  SELECT @cmd = 'CREATE LOGIN tSQLtAssemblyKey FROM ASYMMETRIC KEY tSQLtAssemblyKey;';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  SELECT *
    INTO #Actual
    FROM
    (  
      SELECT AK.name
        FROM master.sys.asymmetric_keys AS AK
       WHERE AK.name = 'tSQLtAssemblyKey'
      UNION ALL
      SELECT SP.name
        FROM master.sys.server_principals AS SP
       WHERE SP.name = 'tSQLtAssemblyKey'
    )A

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual'; --<-- this might blow up if the table isn't empty.
END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test non-sysadmin cannot execute procedure]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
    
  SET @cmd = 'CREATE LOGIN RemoveAssemblyKeyTestsUser1 WITH PASSWORD='''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE USER RemoveAssemblyKeyTestsUser1;ALTER ROLE db_owner ADD MEMBER RemoveAssemblyKeyTestsUser1;';
  IF((SELECT I.SqlVersion FROM tSQLt.Info() AS I) < 11)
  BEGIN
    SET @cmd = 'CREATE USER RemoveAssemblyKeyTestsUser1;EXEC sys.sp_addrolemember @rolename = ''db_owner'', @membername = ''RemoveAssemblyKeyTestsUser1'';';
  END
  EXEC master.sys.sp_executesql @cmd;
  EXEC sys.sp_executesql @cmd;
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Only principals with CONTROL SERVER permission can execute this procedure.';
  
  EXECUTE AS LOGIN = 'RemoveAssemblyKeyTestsUser1';
  EXEC tSQLt.RemoveAssemblyKey;
  REVERT;

END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test login with control server permission can execute procedure]
AS
BEGIN

    EXEC RemoveAssemblyKeyTests.DropExistingItems;

    DECLARE @cmd NVARCHAR(MAX);
    
    SET @cmd = 'CREATE LOGIN RemoveAssemblyKeyTestsUser1 WITH PASSWORD='''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
    EXEC master.sys.sp_executesql @cmd;

    SET @cmd = 'GRANT CONTROL SERVER TO RemoveAssemblyKeyTestsUser1;';
    EXEC master.sys.sp_executesql @cmd;
  
    EXEC tSQLt.ExpectNoException;
  
    EXECUTE AS LOGIN = 'RemoveAssemblyKeyTestsUser1';
      EXEC tSQLt.RemoveAssemblyKey;
    REVERT;

END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes trusted assembly record if it exists]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  DECLARE @TrustedHash NVARCHAR(MAX);

  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;
  SELECT @TrustedHash = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);

  SELECT @cmd = 'EXEC sys.sp_add_trusted_assembly @hash = ' + @TrustedHash +',@description = N''tSQLt Ephemeral'';'  
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  IF(EXISTS(SELECT 1 FROM master.sys.trusted_assemblies WHERE hash = CONVERT(VARBINARY(MAX),@TrustedHash,1)))
  BEGIN
    EXEC tSQLt.Fail 'Trusted Assembly record for tSQLtAssemblyKey not removed.';
  END;
END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE RemoveAssemblyKeyTests.[test doesn't remove trusted assembly record if it is not 'tSQLt Ephemeral']
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @AssemblyKeyBytes VARBINARY(MAX);
  DECLARE @TrustedHash NVARCHAR(MAX);

  EXEC tSQLt.Private_GetAssemblyKeyBytes @AssemblyKeyBytes = @AssemblyKeyBytes OUT;
  SELECT @TrustedHash = CONVERT(NVARCHAR(MAX),HASHBYTES('SHA2_512',@AssemblyKeyBytes),1);

  SELECT @cmd = 'EXEC sys.sp_add_trusted_assembly @hash = ' + @TrustedHash +',@description = N''something else'';'  
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  IF(NOT EXISTS(SELECT 1 FROM master.sys.trusted_assemblies WHERE hash = CONVERT(VARBINARY(MAX),@TrustedHash,1)))
  BEGIN
    EXEC tSQLt.Fail 'Trusted Assembly record for tSQLtAssemblyKey removed despite description <> ''tSQLt Ephemeral''.';
  END;
END;
GO
