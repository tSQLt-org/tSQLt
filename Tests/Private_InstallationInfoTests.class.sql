EXEC tSQLt.NewTestClass 'Private_InstallationInfoTests';
GO
CREATE PROCEDURE Private_InstallationInfoTests.[test returns current SqlVersion]
AS
BEGIN
  SELECT SqlVersion INTO #actual FROM tSQLt.Private_InstallationInfo();

  SELECT SqlVersion INTO #expected FROM tSQLt.Info();
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE FUNCTION Private_InstallationInfoTests.[return 98.76]()
RETURNS TABLE
AS
RETURN SELECT CAST(98.76 AS NUMERIC(10,2)) AS SqlVersion;
GO
CREATE PROCEDURE Private_InstallationInfoTests.[test returns SqlVersion from tSQLt.Info after new install]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Info', @FakeFunctionName = 'Private_InstallationInfoTests.[return 98.76]';
  EXEC tSQLt.Private_CreateInstallationInfo;
  SELECT SqlVersion INTO #Actual FROM tSQLt.Private_InstallationInfo();

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(98.76);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
