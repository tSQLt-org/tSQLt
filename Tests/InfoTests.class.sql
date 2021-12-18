EXEC tSQLt.NewTestClass 'InfoTests';
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a Version column containing latest build number]
AS
BEGIN
  DECLARE @Version NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @Version = Version
    FROM tSQLt.Info();
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  
  
  IF(@ClrInfo NOT LIKE '%version='+@Version+'%')
  BEGIN
    EXEC tSQLt.Fail 'Expected ''version=',@Version,''' to be part of ''',@ClrInfo,'''.'
  END
END;
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a ClrSigningKey column containing the binary thumbprint of the signing key]
AS
BEGIN
  DECLARE @SigningKeyPattern NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @SigningKeyPattern = '%publickeytoken='+LOWER(CONVERT(NVARCHAR(MAX),I.ClrSigningKey,2))+',%'
    FROM tSQLt.Info() I;
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  

  EXEC tSQLt.AssertLike @ExpectedPattern = @SigningKeyPattern, @Actual = @ClrInfo, @Message = 'The value returned by tSQLt.Info().ClrSigningKey was not part of the clr_name of the assembly' ;  
END;
GO
CREATE FUNCTION InfoTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition, NULL HostPlatform;
GO
CREATE PROCEDURE InfoTests.[test returns HostPlatform]
AS
BEGIN

  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_HostPlatform';
  EXEC('INSERT INTO tSQLt.Private_HostPlatform(host_platform) VALUES (''SomePlatform'');');

  SELECT I.HostPlatform
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('SomePlatform');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test returns SqlVersion and SqlBuild]
AS
BEGIN

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlVersion, I.SqlBuild
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(42.17, 1986.57);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test returns SqlEdition]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlEdition
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Edition');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE FUNCTION InfoTests.[return 97.53]()
RETURNS TABLE
AS
RETURN SELECT CAST(97.53 AS NUMERIC(10,2)) AS SqlVersion;
GO
CREATE PROCEDURE InfoTests.[test returns InstalledOnSqlVersion]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_InstallationInfo', @FakeFunctionName = 'InfoTests.[return 97.53]';

  SELECT I.InstalledOnSqlVersion
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(97.53);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE InfoTests.[test returns correct HostPlatform on SQL versions >= 2017]
AS
BEGIN

  SELECT PSV.HostPlatform
    INTO #Actual
    FROM tSQLt.Info() AS PSV;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  SELECT 
		    host_platform HostPlatform 
    FROM sys.dm_os_host_info;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](13)
CREATE PROCEDURE InfoTests.[test returns 'Windows' for HostPlatform on SQL versions < 2017]
AS
BEGIN

  SELECT PSV.HostPlatform
    INTO #Actual
    FROM tSQLt.Info() AS PSV;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected VALUES('Windows');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;

