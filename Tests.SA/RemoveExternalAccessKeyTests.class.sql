EXEC tSQLt.NewTestClass 'RemoveExternalAccessKeyTests';
GO
DECLARE @cmd NVARCHAR(MAX);
SET @cmd = 'IF(SUSER_ID(''RemoveExternalAccessKeyTestsUser1'')) IS NOT NULL DROP LOGIN RemoveExternalAccessKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
SET @cmd = 'IF(SCHEMA_ID(''RemoveExternalAccessKeyTestsUser1'')) IS NOT NULL DROP SCHEMA RemoveExternalAccessKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
SET @cmd = 'IF(USER_ID(''RemoveExternalAccessKeyTestsUser1'')) IS NOT NULL DROP USER RemoveExternalAccessKeyTestsUser1;';
EXEC master.sys.sp_executesql @cmd;
EXEC sys.sp_executesql @cmd;
GO
CREATE PROCEDURE RemoveExternalAccessKeyTests.DropExistingItems
AS
BEGIN
  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;
  EXEC master.sys.sp_executesql N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
END;
GO
GO
CREATE PROCEDURE RemoveExternalAccessKeyTests.[test removes tSQLtExternalAccessKey assembly]
AS
BEGIN
  EXEC RemoveExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtExternalAccessKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt_testutil.GetUnsignedEmptyBytes() AS GUEB
   CROSS APPLY tSQLt.Private_Bin2Hex(GUEB.UnsignedEmptyBytes) AS BH;
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT *
    INTO #Actual
    FROM master.sys.assemblies AS A
   WHERE A.name = 'tSQLtExternalAccessKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test removes tSQLtExternalAccessKey certificate]
AS
BEGIN
  EXEC RemoveExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT *
    INTO #Actual
    FROM master.sys.asymmetric_keys AS AK
   WHERE AK.name = 'tSQLtExternalAccessKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test removes tSQLtExternalAccessKey login]
AS
BEGIN
  EXEC RemoveExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE LOGIN tSQLtExternalAccessKey WITH PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT *
    INTO #Actual
    FROM master.sys.server_principals AS SP
   WHERE SP.name = 'tSQLtExternalAccessKey'

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test removes tSQLtExternalAccessKey certificate and login in correct order]
AS
BEGIN
  EXEC RemoveExternalAccessKeyTests.DropExistingItems;

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = '''+(SELECT PW FROM tSQLt_testutil.GenerateRandomPassword(NEWID()))+''';';
  EXEC master.sys.sp_executesql @cmd;
  SELECT @cmd = 'CREATE LOGIN tSQLtExternalAccessKey FROM ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC master.sys.sp_executesql @cmd;
  
  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT *
    INTO #Actual
    FROM
    (  
      SELECT AK.name
        FROM master.sys.asymmetric_keys AS AK
       WHERE AK.name = 'tSQLtExternalAccessKey'
      UNION ALL
      SELECT SP.name
        FROM master.sys.server_principals AS SP
       WHERE SP.name = 'tSQLtExternalAccessKey'
    )A
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test non-sysadmin cannot execute procedure]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
    
  SET @cmd = 'CREATE LOGIN RemoveExternalAccessKeyTestsUser1 WITH PASSWORD=''(*&^#@($&^%(&@#^$%(!&@'';';
  EXEC master.sys.sp_executesql @cmd;

  SET @cmd = 'CREATE USER RemoveExternalAccessKeyTestsUser1;ALTER ROLE db_owner ADD MEMBER RemoveExternalAccessKeyTestsUser1;';
  IF((SELECT I.SqlVersion FROM tSQLt.Info() AS I) < 11)
  BEGIN
    SET @cmd = 'CREATE USER RemoveExternalAccessKeyTestsUser1;EXEC sys.sp_addrolemember @rolename = ''db_owner'', @membername = ''RemoveExternalAccessKeyTestsUser1'';';
  END
  EXEC master.sys.sp_executesql @cmd;
  EXEC sys.sp_executesql @cmd;
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Only principals with CONTROL SERVER permission can execute this procedure.';
  
  EXECUTE AS LOGIN = 'RemoveExternalAccessKeyTestsUser1';
  EXEC tSQLt.RemoveExternalAccessKey;
  REVERT;

END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test login with control server can execute procedure]
AS
BEGIN

    EXEC RemoveExternalAccessKeyTests.DropExistingItems;

    DECLARE @cmd NVARCHAR(MAX);
    
    SET @cmd = 'CREATE LOGIN RemoveExternalAccessKeyTestsUser1 WITH PASSWORD=''(*&^#@($&^%(&@#^$%(!&@'';';
    EXEC master.sys.sp_executesql @cmd;

    SET @cmd = 'GRANT CONTROL SERVER TO RemoveExternalAccessKeyTestsUser1;';
    EXEC master.sys.sp_executesql @cmd;
  
    EXEC tSQLt.ExpectNoException;
  
    EXECUTE AS LOGIN = 'RemoveExternalAccessKeyTestsUser1';
      EXEC tSQLt.RemoveExternalAccessKey;
    REVERT;

END;
GO

