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
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns passed in ProductVersion]
AS
BEGIN

  SELECT ProductVersion INTO #Actual FROM tSQLt.FriendlySQLServerVersion('15.00.1.1234');

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('15.00.1.1234');

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
  CREATE TABLE #Versions (ProductVersion NVARCHAR(128), FriendlyVersion NVARCHAR(128));
  INSERT INTO #Versions
  VALUES('15.0','2019'),
        ('14.0','2017'),
        ('13.0','2016'),
        ('12.0','2014'),
        ('11.0','2012'),
        ('10.5','2008R2'),
        ('10.0','2008');

  SELECT E.ProductVersion, FSSV.FriendlyVersion
    INTO #Actual
    FROM #Versions AS E
   CROSS APPLY tSQLt.FriendlySQLServerVersion(E.ProductVersion) FSSV;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected SELECT * FROM #Versions;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns the right friendly versions for the official version]
AS
BEGIN
  CREATE TABLE #Versions (ProductVersion NVARCHAR(128), FriendlyVersion NVARCHAR(128));
  INSERT INTO #Versions
  VALUES('15.0.2080.9','2019'),
        ('14.0.2037.2','2017'),
        ('13.0.5026.0','2016'),
        ('13.0.4001.0','2016'),
        ('12.0.6024.0','2014'),
        ('12.0.4100.1','2014'),
        ('11.0.7001.0','2012'),
        ('11.0.3000.00','2012'),
        ('10.50.6000.34','2008R2'),
        ('10.50.4000.0','2008R2'),
        ('10.00.5500.00','2008'),
        ('10.0.6000.29','2008');

  SELECT E.ProductVersion, FSSV.FriendlyVersion
    INTO #Actual
    FROM #Versions AS E
   CROSS APPLY tSQLt.FriendlySQLServerVersion(E.ProductVersion) FSSV;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected SELECT * FROM #Versions;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.[test never returns NULL for the actual ProductVersion]
AS
BEGIN

  SELECT * INTO #Actual
    FROM tSQLt.FriendlySQLServerVersion(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)))
   WHERE FriendlyVersion IS NULL;

  EXEC tSQLt.AssertEmptyTable '#Actual';
  
END;
GO
CREATE PROCEDURE FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion
  @Productversion NVARCHAR(128),
  @ExpectedVersion NVARCHAR(128)
AS
BEGIN
  SELECT FriendlyVersion INTO #Actual
    FROM tSQLt.FriendlySQLServerVersion(@Productversion);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(@ExpectedVersion);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](15)
--[@tSQLt:MinSqlMajorVersion](15)
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2019 for the actual ProductVersion on 2019]
AS
BEGIN
  DECLARE @CurrentProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
  EXEC FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion 
         @Productversion = @CurrentProductVersion,
         @ExpectedVersion = '2019';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](14)
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2017 for the actual ProductVersion on 2017]
AS
BEGIN
  DECLARE @CurrentProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
  EXEC FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion 
         @Productversion = @CurrentProductVersion,
         @ExpectedVersion = '2017';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](13)
--[@tSQLt:MinSqlMajorVersion](13)
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2016 for the actual ProductVersion on 2016]
AS
BEGIN
  DECLARE @CurrentProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
  EXEC FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion 
         @Productversion = @CurrentProductVersion,
         @ExpectedVersion = '2016';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](12)
--[@tSQLt:MinSqlMajorVersion](12)
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2014 for the actual ProductVersion on 2014]
AS
BEGIN
  DECLARE @CurrentProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
  EXEC FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion 
         @Productversion = @CurrentProductVersion,
         @ExpectedVersion = '2014';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](11)
--[@tSQLt:MinSqlMajorVersion](11)
CREATE PROCEDURE FriendlySQLServerVersionTests.[test returns 2012 for the actual ProductVersion on 2012]
AS
BEGIN
  DECLARE @CurrentProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
  EXEC FriendlySQLServerVersionTests.AssertReturnsCorrectFriendlyVersion 
         @Productversion = @CurrentProductVersion,
         @ExpectedVersion = '2012';
END;
GO
