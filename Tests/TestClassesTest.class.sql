EXEC tSQLt.NewTestClass @ClassName = 'TestClassesTests';
GO
CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns a class that is owned by 'tSQLt.TestClass']
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC ('CREATE SCHEMA tSQLtTestDummyA AUTHORIZATION [tSQLt.TestClass];');

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLtTestDummyA');
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO
CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns test classes of all types]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC ('CREATE SCHEMA tSQLtTestDummyA AUTHORIZATION [tSQLt.TestClass];');
  EXEC ('CREATE SCHEMA tSQLtTestDummyB AUTHORIZATION [tSQLt.TestClass];');
  EXEC ('CREATE SCHEMA tSQLtTestDummyC AUTHORIZATION [tSQLt.TestClass];');
  EXEC tSQLt.NewTestClass 'tSQLtTestDummyD';
  EXEC tSQLt.NewTestClass 'tSQLtTestDummyE';


  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected(Name)
  VALUES ('tSQLtTestDummyA'),
         ('tSQLtTestDummyB'),
         ('tSQLtTestDummyC'),
         ('tSQLtTestDummyD'),
         ('tSQLtTestDummyE');
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO
CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns no test classes when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns single test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_B');
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE TestClassesTests.[test tSQLt.TestClasses returns other important columns]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name,SchemaId
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name, SchemaId) VALUES ('tSQLt_test_dummy_A',SCHEMA_ID('tSQLt_test_dummy_A'));
    
  EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO
