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
END;
GO
GO
CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey assembly]
AS
BEGIN
  EXEC RemoveAssemblyKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtAssemblyKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB
   CROSS APPLY tSQLt.Private_Bin2Hex(GUEB.UnsignedEmptyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveAssemblyKey;

  SELECT *
    INTO #Actual
    FROM master.sys.assemblies AS A
   WHERE A.name = 'tSQLtAssemblyKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual'; --<-- this might blow up if the table isn't empty.
END;
GO

CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey certificate]
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

CREATE PROCEDURE RemoveAssemblyKeyTests.[test removes tSQLtAssemblyKey certificate and login in correct order]
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

CREATE PROCEDURE RemoveAssemblyKeyTests.[test login with control server can execute procedure]
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

