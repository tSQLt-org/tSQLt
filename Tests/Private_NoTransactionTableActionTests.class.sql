EXEC tSQLt.NewTestClass 'Private_NoTransactionTableActionTests';
GO
CREATE PROCEDURE Private_NoTransactionTableActionTests.[test contains all tSQLt tables]
AS
BEGIN
  SELECT Name INTO #Actual FROM tSQLt.Private_NoTransactionTableAction;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  SELECT QUOTENAME(SCHEMA_NAME(t.schema_id))+'.'+QUOTENAME(t.name) 
    FROM sys.tables t WHERE schema_id = SCHEMA_ID('tSQLt') AND name NOT LIKE ('%SpyProcedureLog');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_NoTransactionTableActionTests.[test has the correct actions for all tSQLt tables]
AS
BEGIN
  SELECT Name, Action INTO #Actual FROM tSQLt.Private_NoTransactionTableAction;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    SELECT '[tSQLt].[Private_NewTestClassList]','Hide' UNION ALL
    SELECT '[tSQLt].[Run_LastExecution]',       'Hide' UNION ALL
    SELECT '[tSQLt].[Private_Configurations]',  'Restore' UNION ALL
    SELECT '[tSQLt].[CaptureOutputLog]',        'Truncate'  UNION ALL
    SELECT '[tSQLt].[Private_RenamedObjectLog]','Ignore'  UNION ALL
    SELECT '[tSQLt].[TestResult]',              'Ignore';
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO