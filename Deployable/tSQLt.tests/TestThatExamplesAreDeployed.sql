/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
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
       VALUES ('test ready for experimentation if 2 particles', 'Failure');
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
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test status message includes the number of particles', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test foreign key is not violated if Particle color is in Color table', 'Success');
  INSERT INTO #Expected (TestCase, Result)
       VALUES ('test foreign key violated if Particle color is not in Color table', 'Success');
  
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO