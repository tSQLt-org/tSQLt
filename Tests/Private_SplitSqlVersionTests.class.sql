EXEC tSQLt.NewTestClass 'Private_SplitSqlVersionTests';
GO
CREATE PROCEDURE Private_SplitSqlVersionTests.[test splits a 4-part version correctly]
AS
BEGIN
  SELECT Major,
         Minor,
         Build,
         Revision 
    INTO #Actual
    FROM tSQLt.Private_SplitSqlVersion('15.0.1.2345');
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('15','0','1','2345');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_SplitSqlVersionTests.[test works with shorter versions]
AS
BEGIN
  SELECT Major,
         Minor,
         Build,
         Revision 
    INTO #Actual
    FROM (VALUES('15.0.1'),('14.2'),('13'))Versions(V)
   CROSS APPLY tSQLt.Private_SplitSqlVersion(Versions.V);

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('15','0','1',NULL);
  INSERT INTO #Expected VALUES('14','2',NULL,NULL);
  INSERT INTO #Expected VALUES('13',NULL,NULL,NULL);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
