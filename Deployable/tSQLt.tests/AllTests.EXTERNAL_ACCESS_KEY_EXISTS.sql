EXEC tSQLt.NewTestClass 'EnableExternalAccessTests';
GO
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
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error with details, if setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'The attempt to enable tSQLt features requiring EXTERNAL_ACCESS failed: ALTER ASSEMBLY%tSQLtCLR%failed%EXTERNAL_ACCESS%';
  EXEC tSQLt.EnableExternalAccess;
END;
GO
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
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess produces no output, if @try = 1 and setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

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

CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error if disabling fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = SM.definition FROM sys.sql_modules AS SM WHERE SM.object_id = OBJECT_ID('tSQLt.EnableExternalAccess');

  DECLARE @TranName VARCHAR(32);SET @TranName = REPLACE((CAST(NEWID() AS VARCHAR(36))),'-','');
  SAVE TRAN @TranName;
    EXEC tSQLt.Uninstall;
    EXEC('CREATE SCHEMA tSQLt;');
    EXEC(@cmd);

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

CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess retunrs -1, if @try = 1 and setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

  DECLARE @Actual INT;
  EXEC @Actual = tSQLt.EnableExternalAccess @try = 1;
  
  EXEC tSQLt.AssertEquals -1,@Actual;
END;
GO

CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess retunrs 0, if @try = 1 and setting is successful]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;

  DECLARE @Actual INT;
  EXEC @Actual = tSQLt.EnableExternalAccess @try = 1;
  
  EXEC tSQLt.AssertEquals 0,@Actual;
END;
GO




GO

EXEC tSQLt.NewTestClass 'Private_InitTests_EAKE';
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init enables external access if possible]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  
  EXEC tSQLt.Private_Init;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = A.permission_set_desc FROM sys.assemblies AS A WHERE A.name = 'tSQLtCLR';

  EXEC tSQLt.AssertEqualsString @Expected = 'EXTERNAL_ACCESS', @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init does not fail if external access isn't possible]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC('EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;');

  EXEC tSQLt.ExpectNoException;  
  EXEC tSQLt.Private_Init;

END;
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init fails if CLR cannot be accessed]
AS
BEGIN
  EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;');

  EXEC('EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Cannot access CLR. Assembly might be in an invalid state. Try running EXEC tSQLt.EnableExternalAccess @enable = 0; or reinstalling tSQLt.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_Init;

END;
GO
CREATE FUNCTION Private_InitTests_EAKE.[mismatching versions]()
RETURNS TABLE
AS
RETURN SELECT '1234' Version, '4567' ClrVersion;
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init fails if versions do not match]
AS
BEGIN
  
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'Private_InitTests_EAKE.[mismatching versions]';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an invalid state. Please reinstall tSQLt.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_Init;

END;
GO
CREATE FUNCTION Private_InitTests_EAKE.[SQL Azure Edition]()
RETURNS TABLE
AS
RETURN SELECT '1' Version, '1' ClrVersion, 'SQL Azure' SqlEdition;
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test does not call EnableExternalAccess if Edition='SQL Azure']
AS
BEGIN
  
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'Private_InitTests_EAKE.[SQL Azure Edition]';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.EnableExternalAccess', @CommandToExecute = NULL;

  EXEC tSQLt.Private_Init;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.EnableExternalAccess_SpyProcedureLog';

END;
GO


GO

