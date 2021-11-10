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
--[@tSQLt:SkipTest]('TODO: needs other tests first')
CREATE PROCEDURE AnnotationNoTransactionTests.[test produces meaningful error when pre and post transactions counts don't match]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS BEGIN TRAN;
  ');

  --EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test succeeding test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction]()
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RETURN;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT * FROM tSQLt.TestResult AS TR
  EXEC tSQLt.Fail 'TODO: testname, TranName, Result';
END;
GO
/*-- TODO

-- transaction opened during test
-- transaction commited during test
-- test skipped?
-- inner-transaction-free test succeeds
-- inner-transaction-free test fails
-- inner-transaction-free test errors
-- cleanup execution tables
-- named cleanup (needs to execute even if there's an error during test execution)
-- confirm pre and post transaction counts match
-- [test produces meaningful error when pre and post transactions counts don't match]

--*/