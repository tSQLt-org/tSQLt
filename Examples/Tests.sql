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
EXEC tSQLt.NewTestClass 'AcceleratorTests';
GO

CREATE PROCEDURE 
  AcceleratorTests.[test ready for experimentation if 2 particles]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure 
  --          it is empty and has no constraints
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  INSERT INTO Accelerator.Particle (Id) VALUES (2);
  
  DECLARE @Ready BIT;
  
  --Act: Call the IsExperimentReady function
  SELECT @Ready = Accelerator.IsExperimentReady();
  
  --Assert: Check that 1 is returned from IsExperimentReady
  EXEC tSQLt.AssertEquals 1, @Ready;
  
END;
GO

CREATE PROCEDURE AcceleratorTests.[test we are not ready for experimentation if there is only 1 particle]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and has no constraints
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  
  DECLARE @Ready BIT;
  
  --Act: Call the IsExperimentReady function
  SELECT @Ready = Accelerator.IsExperimentReady();
  
  --Assert: Check that 0 is returned from IsExperimentReady
  EXEC tSQLt.AssertEquals 0, @Ready;
  
END;
GO

CREATE PROCEDURE AcceleratorTests.[test no particles are in a rectangle when there are no particles in the table]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty
  EXEC tSQLt.FakeTable 'Accelerator.Particle';

  DECLARE @ParticlesInRectangle INT;
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the number of rows it returns.
  SELECT @ParticlesInRectangle = COUNT(1)
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
  
  --Assert: Check that 0 rows were returned
  EXEC tSQLt.AssertEquals 0, @ParticlesInRectangle;
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put a test particle into the table
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (1, 0.5, 0.5);
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the Id column into the #Actual temp table
  SELECT Id
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
  
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
  
  --        A single row with an Id value of 1 is expected
  INSERT INTO #Expected (Id) VALUES (1);

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned with an Id, Point Location and Value]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put a test particle into the table
  INSERT INTO Accelerator.Particle (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the relevant columns into the #Actual temp table
  SELECT Id, X, Y, Value
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  --        A single row with the expected data is inserted into the #Expected table
  INSERT INTO #Expected (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle is included only if it fits inside the boundaries of the rectangle]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Populate the Particle table with rows that hug the rectangle boundaries
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 1, -0.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 2,  0.00,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 3,  0.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 4,  0.99,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 5,  1.00,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 6,  1.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 7,  0.50, -0.01);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 8,  0.50,  0.00);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 9,  0.50,  0.01);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (10,  0.50,  0.99);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (11,  0.50,  1.00);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (12,  0.50,  1.01);
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the relevant columns into the #Actual temp table
  SELECT Id, X, Y
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  --        The expected data is inserted into the #Expected table
  INSERT INTO #Expected (Id, X, Y) VALUES (3,  0.01, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (4,  0.99, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (9,  0.50, 0.01);
  INSERT INTO #Expected (Id, X, Y) VALUES (10, 0.50, 0.99);
    
  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test email is sent if we detected a higgs-boson]
AS
BEGIN
  --Assemble: Replace the SendHiggsBosonDiscoveryEmail with a spy. 
  EXEC tSQLt.SpyProcedure 'Accelerator.SendHiggsBosonDiscoveryEmail';
  
  --Act: Call the AlertParticleDiscovered procedure - this is the procedure being tested.
  EXEC Accelerator.AlertParticleDiscovered 'Higgs Boson';
  
  --Assert: A spy records the parameters passed to the procedure in a *_SpyProcedureLog table. 
  --        Copy the EmailAddress parameter values that the spy recorded into the #Actual temp table.
  SELECT EmailAddress
    INTO #Actual
    FROM Accelerator.SendHiggsBosonDiscoveryEmail_SpyProcedureLog;
    
  --        Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  --        Add a row to the #Expected table with the expected email address.
  INSERT INTO #Expected 
    (EmailAddress)
  VALUES 
    ('particle-discovery@new-era-particles.tsqlt.org');

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


CREATE PROCEDURE AcceleratorTests.[test email is not sent if we detected something other than higgs-boson]
AS
BEGIN
  --Assemble: Replace the SendHiggsBosonDiscoveryEmail with a spy. 
  EXEC tSQLt.SpyProcedure 'Accelerator.SendHiggsBosonDiscoveryEmail';
  
  --Act: Call the AlertParticleDiscovered procedure - this is the procedure being tested.
  EXEC Accelerator.AlertParticleDiscovered 'Proton';
  
  --Assert: A spy records the parameters passed to the procedure in a *_SpyProcedureLog table. 
  --        Copy the EmailAddress parameter values that the spy recorded into the #Actual temp table.
  SELECT EmailAddress
    INTO #Actual
    FROM Accelerator.SendHiggsBosonDiscoveryEmail_SpyProcedureLog;
    
  --        Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  --        The SendHiggsBosonDiscoveryEmail should not have been called. So the #Expected table is empty.
  
  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

END;
GO

CREATE PROCEDURE AcceleratorTests.[test status message includes the number of particles]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put 3 test particles into the table
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  INSERT INTO Accelerator.Particle (Id) VALUES (2);
  INSERT INTO Accelerator.Particle (Id) VALUES (3);

  --Act: Call the GetStatusMessageFunction
  DECLARE @StatusMessage NVARCHAR(MAX);
  SELECT @StatusMessage = Accelerator.GetStatusMessage();

  --Assert: Make sure the status message is correct
  EXEC tSQLt.AssertEqualsString 'The Accelerator is prepared with 3 particles.', @StatusMessage;
END;
GO

CREATE PROCEDURE AcceleratorTests.[test foreign key violated if Particle color is not in Color table]
AS
BEGIN
  --Assemble: Fake the Particle and the Color tables to make sure they are empty and other 
  --          constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  EXEC tSQLt.FakeTable 'Accelerator.Color';
  --          Put the FK_ParticleColor foreign key constraint back onto the Particle table
  --          so we can test it.
  EXEC tSQLt.ApplyConstraint 'Accelerator.Particle', 'FK_ParticleColor';
  
  --Act: Attempt to insert a record into the Particle table without any records in Color table.
  --     We expect an exception to happen, so we capture the ERROR_MESSAGE()
  DECLARE @err NVARCHAR(MAX); SET @err = '<No Exception Thrown!>';
  BEGIN TRY
    INSERT INTO Accelerator.Particle (ColorId) VALUES (7);
  END TRY
  BEGIN CATCH
    SET @err = ERROR_MESSAGE();
  END CATCH
  
  --Assert: Check that trying to insert the record resulted in the FK_ParticleColor foreign key being violated.
  --        If no exception happened the value of @err is still '<No Exception Thrown>'.
  IF (@err NOT LIKE '%FK_ParticleColor%')
  BEGIN
    EXEC tSQLt.Fail 'Expected exception (FK_ParticleColor exception) not thrown. Instead:',@err;
  END;
END;
GO

CREATE PROC AcceleratorTests.[test foreign key is not violated if Particle color is in Color table]
AS
BEGIN
  --Assemble: Fake the Particle and the Color tables to make sure they are empty and other 
  --          constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  EXEC tSQLt.FakeTable 'Accelerator.Color';
  --          Put the FK_ParticleColor foreign key constraint back onto the Particle table
  --          so we can test it.
  EXEC tSQLt.ApplyConstraint 'Accelerator.Particle', 'FK_ParticleColor';
  
  --          Insert a record into the Color table. We'll reference this Id again in the Act
  --          step.
  INSERT INTO Accelerator.Color (Id) VALUES (7);
  
  --Act: Attempt to insert a record into the Particle table.
  INSERT INTO Accelerator.Particle (ColorId) VALUES (7);
  
  --Assert: If any exception was thrown, the test will automatically fail. Therefore, the test
  --        passes as long as there was no exception. This is one of the VERY rare cases when
  --        at test case does not have an Assert step.
END
GO