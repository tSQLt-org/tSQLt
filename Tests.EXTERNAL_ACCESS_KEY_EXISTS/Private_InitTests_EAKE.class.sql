EXEC tSQLt.NewTestClass 'Private_InitTests_EAKE';
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
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
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init does not fail if enabling external access isn't possible]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.EnableExternalAccess', @CommandToExecute = NULL;

  EXEC tSQLt.Private_Init;

  SELECT [try] INTO #Actual FROM tSQLt.EnableExternalAccess_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES (1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](13)
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init fails if CLR cannot be accessed]
AS
BEGIN
  EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;');

  EXEC('EXEC master.tSQLt_testutil.tSQLtTestUtil_UnsafeAssemblyAndExternalAccessRevoke;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Cannot access CLR. Assembly might be in an invalid state. Try running EXEC tSQLt.EnableExternalAccess @enable = 0; or reinstalling tSQLt.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_Init;

END;
GO
CREATE FUNCTION Private_InitTests_EAKE.[SQL Azure Edition]()
RETURNS TABLE
AS
RETURN SELECT '1' Version, '1' ClrVersion, 0 SqlVersion, NULL SqlBuild, 'SQL Azure' SqlEdition, 'Windows' HostPlatform, 0 InstalledOnSqlVersion;
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
CREATE FUNCTION Private_InitTests_EAKE.[HostPlatform Linux]()
RETURNS TABLE
AS
RETURN SELECT '1' Version, '1' ClrVersion, NULL SqlVersion, NULL SqlBuild, 'Developer Edition (64-bit)' SqlEdition, 'Linux' HostPlatform;
GO
