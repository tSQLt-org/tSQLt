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
CREATE FUNCTION InfoTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion;
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