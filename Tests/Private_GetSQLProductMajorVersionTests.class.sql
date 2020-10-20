EXEC tSQLt.NewTestClass 'Private_GetSQLProductMajorVersionTests';
GO
--[@tSQLt:MinSqlMajorVersion](10)
--[@tSQLt:MaxSqlMajorVersion](10)
CREATE PROCEDURE Private_GetSQLProductMajorVersionTests.[test return correct version on SQL Version = 10]
AS
BEGIN
  DECLARE @Version INT;
  EXEC @Version = tSQLt.Private_GetSQLProductMajorVersion;
  
  EXEC tSQLt.AssertEquals @Expected = 10, @Actual = @Version;  
END;
GO
--[@tSQLt:MinSqlMajorVersion](15)
--[@tSQLt:MaxSqlMajorVersion](15)
CREATE PROCEDURE Private_GetSQLProductMajorVersionTests.[test return correct version on SQL Version = 15]
AS
BEGIN
  DECLARE @Version INT;
  EXEC @Version = tSQLt.Private_GetSQLProductMajorVersion;
  
  EXEC tSQLt.AssertEquals @Expected = 15, @Actual = @Version;  
END;
