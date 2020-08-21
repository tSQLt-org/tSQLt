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
EXEC tSQLt.Fail 'should write testutil.assertskipped -- also see if there can be a reason message';
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
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
  INSERT INTO #Expected VALUES('test should not execute','Skipped');
 
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
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
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
  INSERT INTO #Expected VALUES('test should not execute','Skipped');
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if it encounters a nonexistent annotation]
AS
BEGIN
  EXEC tSQLt.Fail 'This should be two tests (or tSQLt_testutil.AssertTestErrors should assert error status)';
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:ANonexistentAnnotation]
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
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
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:A1ParameterAnnotation] @P1 INT AS RETURN;');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is superfluous]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation] @P1 = 3, @P2 = 42;
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:A1ParameterAnnotation] @P1 INT AS RETURN;');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test concats actual error message to Msg in new line]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:AnErroringAnnotation] AS RAISERROR(''SpecificErrorMessageInsideAnnotation'',16,10);');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%SpecificErrorMessageInsideAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test includes procedure, severity, and state]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:AnErroringAnnotation] AS RAISERROR(''SpecificErrorMessageInsideAnnotation'',15,9);');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{15,9;[[]@tSQLt:AnErroringAnnotation]}%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test can handle string as parameter]
AS
BEGIN
  DECLARE @AnnotationName NVARCHAR(MAX) = '[@tSQLt:AStringParameterAnnotation]';
  DECLARE @FullAnnotationName NVARCHAR(MAX) = 'tSQLt.'+@AnnotationName;
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--'+@AnnotationName+' @P1 = ''SomeRandomString''
CREATE PROCEDURE MyInnerTests.[test nothing] AS RETURN;
  ');
  EXEC('CREATE PROCEDURE '+@FullAnnotationName+' @P1 NVARCHAR(MAX) AS RAISERROR(''[%s]'',16,10,@P1);');

  EXEC tSQLt_testutil.AssertTestErrors @TestName = 'MyInnerTests.[test nothing]', @ExpectedMessage='%[[]SomeRandomString]%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test should we do something about injection?]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]; RAISERROR(''Something Nefarious'',16,10)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotation] AS RETURN;');

  EXEC tSQLt_testutil.AssertTestErrors @TestName = 'MyInnerTests.[test should not execute]', @ExpectedMessage='%Something Nefarious%';
END;
GO



-- Future Tests Log:
---------------------------------------------------------------------------
-- well-formed Annotation within multiline comment should still count
--
-- wrong data type parameter
-- different type of inner errors
--- cast
--- /0
--
-- -------------------+
--                    |
--                    V
--
-- test summary to include skipped in sorting and in total
-- test execution times to include annotations
-- skipped tests to report duration


---------------------------------------------------------------------------
GO
IF(XACT_STATE()<>0)ROLLBACK