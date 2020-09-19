EXEC tSQLt.NewTestClass 'InstallExternalAccessKeyTests';
GO
CREATE PROCEDURE InstallExternalAccessKeyTests.[test calls tSQLt.InstallAssemblyKey]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.InstallAssemblyKey';

  EXEC tSQLt.InstallExternalAccessKey;

  SELECT _id_ INTO #Actual FROM tSQLt.InstallAssemblyKey_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES (1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE InstallExternalAccessKeyTests.[test prints sensible deprecation warning]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.InstallAssemblyKey';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';

  EXEC tSQLt.InstallExternalAccessKey;

  SELECT Message INTO #Actual FROM tSQLt.Private_Print_SpyProcedureLog ;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('tSQLt.InstallExternalAccessKey is deprecated. Please use tSQLt.InstallAssemblyKey instead.');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
