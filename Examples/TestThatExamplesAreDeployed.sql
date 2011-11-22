EXEC tSQLt.NewTestClass 'ExampleDeployed';
GO

CREATE PROCEDURE ExampleDeployed.[test example tests have appropriate successes and failures]
AS
BEGIN
  BEGIN TRY
    EXEC tSQLt.RunTestClass 'AcceleratorTests';
  END TRY
  BEGIN CATCH
  END CATCH
  
  SELECT TestCase, Result
    INTO #Actual
    FROM tSQLt.TestResult;
  
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestCase, Result) 
       VALUES ('test we are ready for experimentation if there are at least 2 particles', 'Failure');
  INSERT INTO #Expected (TestCase, Result) 
       VALUES ('test we are not ready for experimentation if there is only 1 particle', 'Success');
  INSERT INTO #Expected (TestCase, Result) 
       VALUES ('test no particles are in a rectangle when there are no particles in the table', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test a particle within the rectangle is returned', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test a particle within the rectangle is returned with an Id, Point Location and Value', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test a particle is included only if it fits inside the boundaries of the rectangle', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test email is sent if we detected a higgs-boson', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test email is not sent if we detected something other than higgs-boson', 'Success');
  
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO