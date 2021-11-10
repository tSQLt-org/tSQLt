EXEC tSQLt.NewTestClass 'AnnotationNoTransactionTests';
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test runs test without transaction]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS INSERT INTO #TranCount VALUES(''I'',@@TRANCOUNT);;
  ');

  SELECT 'B' Id, @@TRANCOUNT TranCount
    INTO #TranCount;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';

  INSERT INTO #TranCount VALUES('A',@@TRANCOUNT);

  SELECT Id, TranCount-MIN(TranCount)OVER() AdjustedTrancount
    INTO #Actual
    FROM #TranCount;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('B',0),('I',0),('A',0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

/*-- TODO

-- transaction opened during test
-- transaction commited during test
-- test skipped?
-- cleanup execution tables
-- SpyProcedureLog table needs to be marked with IsTempObject in extended properties
-- named cleanup (needs to execute even if there's an error during test execution)
-- confirm pre and post transaction counts match

--*/