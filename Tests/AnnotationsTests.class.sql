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
       @ExpectedMessage='There is a problem with the annotations:%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is missing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation](@P1 INT) RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

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
--[@'+'tSQLt:A1ParameterAnnotation](3,42)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation](@P1 INT) RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test specifies details if there's an internal error in the annotation function]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnErroringAnnotation]() RETURNS TABLE AS RETURN SELECT 1/0 [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{16,10} There is an internal error for annotation: [[]@tSQLt:AnErroringAnnotation]()
  caused by {16,1} Divide by zero error encountered.%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test includes severity, and state]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  DECLARE @Cmd NVARCHAR(MAX) = '
--[@'+CAST(0x7400530051004C0074003A0041006E0041006E006E006F0074006100740069006F006E005D0028002900200041003B0052004100490053004500520052004F005200280027007800780027002C00310035002C00390029003B004400450043004C00410052004500200040007300200049004E0054003B002000530045004C00450043005400200054004F0050002800300029002000400073003D006F0062006A006500630074005F00690064002000660072006F006D0020007300790073002E006F0062006A006500630074007300 AS NVARCHAR(MAX))+'
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';';
  EXEC(@Cmd);
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{15,9}%';
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



-- Future Tests Log:
---------------------------------------------------------------------------
-- well-formed Annotation within multiline comment should still count
--
-- wrong data type parameter
-- different type of inner errors
--- cast  (& figure out if a batch-ending error can be caught better)
--- /0
--- accessing objects or columns that aren't there
--- syntax
--
-- does annotation that causes problem get identified correctly when there are multiple annotations
-- error message when annotation is followed by other characters
-- .
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