EXEC tSQLt.NewTestClass 'AnnotationsTests';
GO
CREATE PROCEDURE AnnotationsTests.[test a test runs if annotation returns 1]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test will execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS BIT AS BEGIN RETURN 1; END;');
  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Msg INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will execute','test executed');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[skip test a test is skipped if annotation returns 0]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test will not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS BIT AS BEGIN RETURN 0; END;');
  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will not execute','Skipped');
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if different annotation returns 0]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
  /*
--[@'+'tSQLt:ADifferentAnnotation]()
*/
CREATE PROCEDURE MyInnerTests.[test will not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:ADifferentAnnotation]() RETURNS BIT AS BEGIN RETURN 0; END;');
  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will not execute','Skipped');
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO


-- Future Tests Log:
---------------------------------------------------------------------------
-- well-formed Annotation within multiline comment should still count
--
---------------------------------------------------------------------------
