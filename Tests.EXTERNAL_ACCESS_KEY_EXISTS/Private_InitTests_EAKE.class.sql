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
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

  EXEC tSQLt.ExpectNoException;  
  EXEC tSQLt.Private_Init;

END;
GO
CREATE PROCEDURE Private_InitTests_EAKE.[test Private_Init fails if CLR cannot be accessed]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

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
