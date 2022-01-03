EXEC tSQLt.NewTestClass 'EnableExternalAccessTests';
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess sets PERMISSION_SET to EXTERNAL_ACCESS if called without parameters]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;

  EXEC tSQLt.EnableExternalAccess;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = A.permission_set_desc FROM sys.assemblies AS A WHERE A.name = 'tSQLtCLR';

  EXEC tSQLt.AssertEqualsString @Expected = 'EXTERNAL_ACCESS', @Actual = @Actual;
END;
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error with details, if setting fails]
AS
BEGIN
  DECLARE @ProductMajorVersion INT;
  EXEC @ProductMajorVersion = tSQLt.Private_GetSQLProductMajorVersion;
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_UnsafeAssemblyAndExternalAccessRevoke;
  DECLARE @ExpectedMessagePattern NVARCHAR(MAX) =  
              'The attempt to enable tSQLt features requiring EXTERNAL_ACCESS failed: ALTER ASSEMBLY%tSQLtCLR%failed%'+
              CASE WHEN @ProductMajorVersion>=14 THEN 'UNSAFE ASSEMBLY' ELSE 'EXTERNAL_ACCESS' END+
              '%';
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = @ExpectedMessagePattern;
  EXEC tSQLt.EnableExternalAccess;
END;
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess sets PERMISSION_SET to SAFE if @enable = 0]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  EXEC tSQLt.EnableExternalAccess @enable = 0;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = A.permission_set_desc FROM sys.assemblies AS A WHERE A.name = 'tSQLtCLR';

  EXEC tSQLt.AssertEqualsString @Expected = 'SAFE_ACCESS', @Actual = @Actual;
END;
GO
--[@tSQLt:MinSqlMajorVersion](11)
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess produces no output, if @try = 1 and setting fails (2012++)]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  CREATE USER EnableExternalAccessTestsTempUser WITHOUT LOGIN;
  GRANT EXECUTE ON tSQLt.EnableExternalAccess TO EnableExternalAccessTestsTempUser;

    EXEC tSQLt.CaptureOutput '
      BEGIN TRY
        EXECUTE AS USER=''EnableExternalAccessTestsTempUser'';
        EXEC tSQLt.EnableExternalAccess @try = 1;
        REVERT;
      END TRY
      BEGIN CATCH
        REVERT;
        DECLARE @msg NVARCHAR(MAX) = ''GOTHERE:''+ERROR_MESSAGE();
        RAISERROR(@msg,16,10);
      END CATCH;
    ';
  
  SELECT OutputText 
    INTO #Actual
    FROM tSQLt.CaptureOutputLog;
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  INSERT INTO #Expected
  VALUES(NULL);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](10)
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess produces no output, if @try = 1 and setting fails (2008,2008R2)]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_UnsafeAssemblyAndExternalAccessRevoke;
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.EnableExternalAccess @try = 1;';
  
  SELECT OutputText 
    INTO #Actual
    FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error if disabling fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  DECLARE @cmdEEA NVARCHAR(MAX);
  SELECT @cmdEEA = SM.definition FROM sys.sql_modules AS SM WHERE SM.object_id = OBJECT_ID('tSQLt.EnableExternalAccess');
  DECLARE @cmdInfo NVARCHAR(MAX);
  SELECT @cmdInfo = 'CREATE FUNCTION tSQLt.Info() RETURNS TABLE AS RETURN SELECT ''Windows'' HostPlatform;';

  DECLARE @TranName VARCHAR(32);SET @TranName = REPLACE((CAST(NEWID() AS VARCHAR(36))),'-','');
  SAVE TRAN @TranName;
    EXEC tSQLt.Uninstall;
    EXEC('CREATE SCHEMA tSQLt;');
    EXEC(@cmdEEA);
    EXEC(@cmdInfo);

    DECLARE @Actual NVARCHAR(MAX);SET @Actual = 'No error raised!';  
    BEGIN TRY
      EXEC tSQLt.EnableExternalAccess @enable = 0;
    END TRY
    BEGIN CATCH
      SET @Actual = ERROR_MESSAGE();
    END CATCH;
  ROLLBACK TRAN @TranName;

  EXEC tSQLt.AssertLike @ExpectedPattern = 'The attempt to disable tSQLt features requiring EXTERNAL_ACCESS failed: %tSQLtCLR%', @Actual = @Actual;
END;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess returns -1, if @try = 1 and setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  CREATE USER EnableExternalAccessTestsTempUser WITHOUT LOGIN;
  SELECT 
      SP.name,
      DP.name,
      SP.type_desc,
      DP.type_desc,
      ISNULL(SP.sid,DP.sid) sid,
      DP.principal_id,
      DP.type,
      DP.default_schema_name,
      DP.create_date,
      DP.modify_date,
      DP.owning_principal_id,
      DP.is_fixed_role,
      SP.principal_id,
      SP.type,
      SP.is_disabled,
      SP.create_date,
      SP.modify_date,
      SP.default_database_name,
      SP.default_language_name,
      SP.credential_id 
    FROM sys.database_principals AS DP
    FULL JOIN sys.server_principals AS SP
      ON SP.sid = DP.sid;

  DECLARE @Actual INT;
  EXECUTE AS USER = 'EnableExternalAccessTestsTempUser';
  SELECT * FROM sys.fn_my_permissions(NULL,NULL) AS FMP;
    RAISERROR('GH1',0,1)WITH NOWAIT;
    EXEC @Actual = tSQLt.EnableExternalAccess @try = 1;
    RAISERROR('GH2',0,1)WITH NOWAIT;
  REVERT
  
  EXEC tSQLt.AssertEquals -1,@Actual;
END;
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess returns 0, if @try = 1 and setting is successful]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;

  DECLARE @Actual INT;
  EXEC @Actual = tSQLt.EnableExternalAccess @try = 1;
  
  EXEC tSQLt.AssertEquals 0,@Actual;
END;
GO
CREATE FUNCTION EnableExternalAccessTests.[HostPlatform Linux]()
RETURNS TABLE
AS
RETURN SELECT '1' Version, '1' ClrVersion, NULL SqlVersion, NULL SqlBuild, 'Developer Edition (64-bit)' SqlEdition, 'Linux' HostPlatform;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error if HostPlatform is Linux]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'EnableExternalAccessTests.[HostPlatform Linux]';

  DECLARE @ExpectedMessagePattern NVARCHAR(MAX) =  
              'tSQLt.EnableExternalAccess is not supported on Linux.';

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = @ExpectedMessagePattern;
  EXEC tSQLt.EnableExternalAccess;
END;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess returns -1, if @try = 1 and HostPlatform is Linux]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'EnableExternalAccessTests.[HostPlatform Linux]';

  DECLARE @Actual INT;
  EXEC @Actual = tSQLt.EnableExternalAccess @try = 1;
  
  EXEC tSQLt.AssertEquals -1,@Actual;
END;
GO


