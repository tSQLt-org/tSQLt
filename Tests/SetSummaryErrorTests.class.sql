EXEC tSQLt.NewTestClass 'SetSummaryErrorTests';
GO
CREATE PROCEDURE SetSummaryErrorTests.CreateTestsSuiteWithFailingTest
AS
BEGIN
  EXEC tSQLt.NewTestClass 'SetSummaryErrorTestsTests';
  EXEC('CREATE PROCEDURE SetSummaryErrorTestsTests.TestPassing AS RETURN 0;');
  EXEC('CREATE PROCEDURE SetSummaryErrorTestsTests.TestFailing AS EXEC tSQLt.Fail;');
END;
GO
CREATE PROCEDURE SetSummaryErrorTests.[test suppresses the error in the summary if set to 0]
AS
BEGIN
  EXEC SetSummaryErrorTests.CreateTestsSuiteWithFailingTest;
  EXEC tSQLt.SetSummaryError @SummaryError=0;
  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.Run @TestName='SetSummaryErrorTestsTests';
END;
GO
CREATE PROCEDURE SetSummaryErrorTests.[test doesn't suppress the error in the summary if not set]
AS
BEGIN
  EXEC SetSummaryErrorTests.CreateTestsSuiteWithFailingTest;
  EXEC tSQLt.ExpectException @ExpectedMessagePattern='Test Case Summary:%';
  EXEC tSQLt.Run @TestName='SetSummaryErrorTestsTests';
END;
GO
CREATE PROCEDURE SetSummaryErrorTests.[test doesn't suppress the error in the summary if set to 1]
AS
BEGIN
  EXEC SetSummaryErrorTests.CreateTestsSuiteWithFailingTest;
  EXEC tSQLt.SetSummaryError @SummaryError=1;
  EXEC tSQLt.ExpectException @ExpectedMessagePattern='Test Case Summary:%';
  EXEC tSQLt.Run @TestName='SetSummaryErrorTestsTests';
END;
GO
CREATE PROCEDURE SetSummaryErrorTests.[test errors if @SummaryError NOT IN (0,1)]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessagePattern='@SummaryError has to be 0 or 1, but it was:%';
  EXEC tSQLt.SetSummaryError @SummaryError=111;
END;
GO
