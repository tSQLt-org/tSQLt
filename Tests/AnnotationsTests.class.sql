EXEC tSQLt.NewTestClass 'AnnotationsTests';
GO
CREATE PROCEDURE AnnotationsTests.[test a test runs if single annotation indicates to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]
CREATE PROCEDURE MyInnerTests.[test will execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotation] AS BEGIN RETURN; END;');
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
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if single annotation indicates not to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]
CREATE PROCEDURE MyInnerTests.[test will not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotation] AS BEGIN INSERT INTO #SkipTest DEFAULT VALUES; END;');
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
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if another single annotation indicates not to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
  /*
--[@'+'tSQLt:ADifferentAnnotation]
*/
CREATE PROCEDURE MyInnerTests.[test will not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:ADifferentAnnotation] AS BEGIN INSERT INTO #SkipTest DEFAULT VALUES; END;');
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
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if it encounters a nonexistent annotation]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:ANonexistentAnnotation]
CREATE PROCEDURE MyInnerTests.[test will error] AS EXEC tSQLt.Fail ''test executed'';
  ');

  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result,
  CASE WHEN Msg LIKE 'There is a problem with this annotation: [[]@tSQLt:ANonexistentAnnotation]%' 
    THEN 'Correct Message'
    ELSE 'Wrong Message: '+Msg
  END MsgOutcome
  INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will error','Error','Correct Message');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is missing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation]
CREATE PROCEDURE MyInnerTests.[test will error] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:A1ParameterAnnotation] @P1 INT AS RETURN;');

  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result
    INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will error','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is superfluous]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation] @P1 = 3, @P2 = 42;
CREATE PROCEDURE MyInnerTests.[test will error] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:A1ParameterAnnotation] @P1 INT AS RETURN;');

  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result
    INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will error','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test concats actual error message to Msg in new line]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]
CREATE PROCEDURE MyInnerTests.[test will error] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:AnErroringAnnotation] @P1 INT AS RAISERROR(''SpecificErrorMessage'',16,10);');

  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Result,Msg
  INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will error','Error','There is a problem with this annotation: [@tSQLt:AnErroringAnnotation]'+CHAR(13)+CHAR(10)+'SpecificErrorMessage');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;


-- Future Tests Log:
---------------------------------------------------------------------------
-- well-formed Annotation within multiline comment should still count
--
-- wrong data type parameter
-- different type of inner errors
--- cast
--- /0
--- includes severity adn state in error message

---------------------------------------------------------------------------
GO
IF(XACT_STATE()<>0)ROLLBACK