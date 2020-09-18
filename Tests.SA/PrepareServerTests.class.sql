EXEC tSQLt.NewTestClass 'PrepareServerTests';
GO
CREATE PROCEDURE PrepareServerTests.[test enables CLR]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_EnableCLR';

  EXEC tSQLt.PrepareServer;

  SELECT COUNT(1) NumberOfCalls
    INTO #Actual
    FROM tSQLt.Private_EnableCLR_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE PrepareServerTests.[test TODO]
AS
BEGIN
  EXEC tSQLt.Fail 'TODO:
  -- call tSQLt.InstallExternalAccessKey  <-- RENAME to tSQLtAssemblyKey
  -- on 2019 add UNSAFE permission (maybe change to instead of add)
  -- change IEAK to be able to run on 2019 without altering server configurations (the bytes of the assembly can be used to create a bytecode over it, add it to the "whitelist" -use exception list- and then you can add it without having to worry about the configuration.)
  
  ';
END;