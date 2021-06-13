EXEC tSQLt.NewTestClass 'FriendlySQLServerVersionTests';
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns NULL if version is unknown]
AS
BEGIN

  SELECT FriendlyVersion INTO #Actual FROM tSQLt.FriendlySQLServerVersion('unknown');

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2019 if version is 15.00]
AS
BEGIN

  SELECT FriendlyVersion INTO #Actual FROM tSQLt.FriendlySQLServerVersion('15.00');

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('2019');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2019 if version is 15.0.2000.5]
AS
BEGIN

  SELECT FriendlyVersion INTO #Actual FROM tSQLt.FriendlySQLServerVersion('15.0.2000.5');

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('2019');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns the right friendly versions]
AS
BEGIN
  CREATE TABLE #Expected (ProductVersion NVARCHAR(128), FriendlyVersion NVARCHAR(128));
  INSERT INTO #Expected
  VALUES('15.0','2019'),
        ('14.0','2017'),
        ('13.0','2016'),
        ('12.0','2014'),
        ('11.0','2012'),
        ('10.5','2008R2'),
        ('10.0','2008');

  SELECT E.ProductVersion, FSSV.FriendlyVersion
    INTO #Actual
    FROM #Expected AS E
   CROSS APPLY tSQLt.FriendlySQLServerVersion(E.ProductVersion) FSSV;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
--tSQLt.Run 'FriendlySQLServerVersionTests'