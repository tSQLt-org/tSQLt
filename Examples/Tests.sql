EXEC tSQLt.NewTestClass 'AcceleratorTests';
GO

CREATE PROCEDURE AcceleratorTests.[test no particles are in a rectangle when there are no particles in the table]
AS
BEGIN
  EXEC tSQLt.FakeTable 'Accelerator.Particle';

  DECLARE @ParticlesInRectangle INT;
  
  SELECT @ParticlesInRectangle = COUNT(1)
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
  
  EXEC tSQLt.AssertEquals 0, @ParticlesInRectangle;
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned]
AS
BEGIN
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (1, 0.5, 0.5);
  
  SELECT Id
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Id) VALUES (1);

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned with an Id, Point Location and Value]
AS
BEGIN
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');
  
  SELECT Id, X, Y, Value
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle is included only if it fits inside the boundaries of the rectangle]
AS
BEGIN
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
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
  
  SELECT Id, X, Y
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Id, X, Y) VALUES (3,  0.01, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (4,  0.99, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (9,  0.50, 0.01);
  INSERT INTO #Expected (Id, X, Y) VALUES (10, 0.50, 0.99);
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO