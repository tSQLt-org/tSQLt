EXEC tSQLt.NewTestClass 'Private_InitTests';
GO
CREATE FUNCTION Private_InitTests.[mismatching ClrVersions]()
RETURNS TABLE
AS
RETURN SELECT '1234' Version, '4567' ClrVersion,CAST(98.76 AS NUMERIC(10,2)) SqlVersion, CAST(98.76 AS NUMERIC(10,2)) InstalledOnSqlVersion, NULL SqlBuild, CAST(NULL AS NVARCHAR(MAX)) SqlEdition;
GO
CREATE PROCEDURE Private_InitTests.[test Private_Init fails if ClrVersion does not match]
AS
BEGIN
  
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'Private_InitTests.[mismatching ClrVersions]';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an invalid state. Please reinstall tSQLt.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_Init;

END;
GO

CREATE FUNCTION Private_InitTests.[mismatching SqlVersions]()
RETURNS TABLE
AS
RETURN SELECT CAST(98.76 AS NUMERIC(10,2)) SqlVersion, CAST(77.53 AS NUMERIC(10,2)) InstalledOnSqlVersion,'1234' Version, '1234' ClrVersion, NULL SqlBuild, CAST(NULL AS NVARCHAR(MAX)) SqlEdition;
GO
CREATE PROCEDURE Private_InitTests.[test Private_Init fails if SqlVersions do not match]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.EnableExternalAccess';
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'Private_InitTests.[mismatching SqlVersions]';

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt is in an invalid state. Please reinstall tSQLt.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_Init;

END;
GO
