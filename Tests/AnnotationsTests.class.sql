EXEC tSQLt.NewTestClass 'AnnotationsTests';
GO
CREATE PROCEDURE AnnotationsTests.[test a test runs if single annotation indicates to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test will execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');
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
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotationProc] AS INSERT INTO #SkipTest DEFAULT VALUES;');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@'+'tSQLt:MyTestAnnotationProc]'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if another single annotation indicates not to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
  /*
--[@'+'tSQLt:ADifferentAnnotation]()
*/
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotationProc] AS INSERT INTO #SkipTest DEFAULT VALUES;');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:ADifferentAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@'+'tSQLt:MyTestAnnotationProc]'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if it encounters a nonexistent annotation]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:ANonexistentAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='There is a problem with this annotation: [[]@tSQLt:ANonexistentAnnotation]%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest errors test with appropriate message if a parameter is missing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest errors test with appropriate message if a parameter is superfluous]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation](3,42);
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest concats actual error message to Msg in new line]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnErroringAnnotation]() RETURNS TABLE AS RETURN SELECT CAST(CAST(''SpecificErrorMessageInsideAnnotation'' AS INT) AS NVARCHAR(MAX) [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%SpecificErrorMessageInsideAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest includes procedure, severity, and state]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:AnErroringAnnotation] AS RAISERROR(''SpecificErrorMessageInsideAnnotation'',15,9);');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{15,9;[[]@tSQLt:AnErroringAnnotation]}%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest can handle string as parameter]
AS
BEGIN
  DECLARE @AnnotationName NVARCHAR(MAX) = '[@tSQLt:AStringParameterAnnotation]';
  DECLARE @FullAnnotationName NVARCHAR(MAX) = 'tSQLt.'+@AnnotationName;
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--'+@AnnotationName+'(''SomeRandomString'')
CREATE PROCEDURE MyInnerTests.[test nothing] AS RETURN;
  ');
  EXEC('CREATE PROCEDURE '+@FullAnnotationName+' @P1 NVARCHAR(MAX) AS RAISERROR(''[%s]'',16,10,@P1);');

  EXEC tSQLt_testutil.AssertTestErrors @TestName = 'MyInnerTests.[test nothing]', @ExpectedMessage='%[[]SomeRandomString]%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[XXtest should we do something about injection?]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation](); RAISERROR(''Something Nefarious'',16,10)
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
-- does annotation that causes problem get identified correctly when there are multiple annotations
--
-- -------------------+
--                    |
--                    V
--
-- test summary to include skipped in sorting and in total
-- test execution times to include annotations
-- skipped tests to report duration
-- skipped tests can have reason message
-- 
/*
SSPs
  Benefits
    more flexible

  Malefits
    allow for simple out-of-compliance code


Functions
  Benefits
    hard to break out of compliance

  Malefits
    no named parameters
    no optional parameters --> less flexible annotations
    somewhat more complex code

*/


---------------------------------------------------------------------------
GO
IF(XACT_STATE()<>0)ROLLBACK