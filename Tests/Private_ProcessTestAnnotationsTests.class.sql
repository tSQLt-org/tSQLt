EXEC tSQLt.NewTestClass 'Private_ProcessTestAnnotationsTests';
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return MyTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation]()' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:AnotherTestAnnotation]()' EscapedAnnotationString,'tSQLt.[@tSQLt:AnotherTestAnnotation]()' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return an annotation with a single quote anywhere on line](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:Annotaton](''''aa)' EscapedAnnotationString,'tSQLt.[@tSQLt:Annotation](''aa)' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return an annotation with an even number of quotes anywhere on line](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotaton](''''aa'''')' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation](''aa'')' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return an annotation with an odd number of quotes anywhere on line](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotaton](''''aa'''',''''bb'''',''''cc)' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation](''aa'',''bb'',''cc)' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return several test Annotations with unmatched quotes](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation1]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation1](''aa'')' Annotation
  UNION ALL 
  SELECT 2 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation2]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation2](''bb'',''cc)' Annotation
  UNION ALL 
  SELECT 3 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation3]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation3](''dd'',''ee'')' Annotation
  UNION ALL 
  SELECT 4 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation4]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation4](''ff'',''gg'',''hh)' Annotation
  UNION ALL 
  SELECT 5 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation5]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation5](''ii'',''jj'',''kk'')' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return 3 Test Annotations](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation1]()' EscapedAnnotationString, 'tSQLt.[@tSQLt:MyTestAnnotation1]()' Annotation
  UNION ALL 
  SELECT 2 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation2]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation2]()' Annotation
  UNION ALL 
  SELECT 3 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation3]()' EscapedAnnotationString,'tSQLt.[@tSQLt:MyTestAnnotation3]()' Annotation;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotationHelper] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotationHelper]';

    EXEC('CREATE PROC tSQLt.[@tSQLt:AnotherTestAnnotationHelper] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:AnotherTestAnnotationHelper]';

    EXEC('CREATE FUNCTION tSQLt.[@tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyTestAnnotationHelper];'' AS AnnotationCmd;');
    EXEC('CREATE FUNCTION tSQLt.[@tSQLt:AnotherTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:AnotherTestAnnotationHelper];'' AS AnnotationCmd;');
END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations
  @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation1Helper] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation1Helper]', @CommandToExecute = @CommandToExecute;
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation2Helper] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation2Helper]', @CommandToExecute = @CommandToExecute;
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation3Helper] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation3Helper]', @CommandToExecute = @CommandToExecute;
    EXEC('CREATE FUNCTION tSQLt.[@tSQLt:MyTestAnnotation1]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyTestAnnotation1Helper];'' AS AnnotationCmd;');
    EXEC('CREATE FUNCTION tSQLt.[@tSQLt:MyTestAnnotation2]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyTestAnnotation2Helper];'' AS AnnotationCmd;');
    EXEC('CREATE FUNCTION tSQLt.[@tSQLt:MyTestAnnotation3]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyTestAnnotation3Helper];'' AS AnnotationCmd;');

END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls annotation procedure]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return MyTestAnnotation]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:MyTestAnnotationHelper_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls AnotherTestAnnotation]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:AnotherTestAnnotationHelper_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls all annotation procedures]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return 3 Test Annotations]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT * 
    INTO #Actual
    FROM
    (
      SELECT 'MyTestAnnotation1' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation1Helper_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation2' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation2Helper_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation3' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation3Helper_SpyProcedureLog]
    )X;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('MyTestAnnotation1'),('MyTestAnnotation2'),('MyTestAnnotation3');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls all annotation procedures in order]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations 'INSERT INTO #Actual VALUES(OBJECT_NAME(@@PROCID));';
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return 3 Test Annotations]';
  
  CREATE TABLE #Actual(CallOrder INT IDENTITY(1,1),Annotation NVARCHAR(MAX));

  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1,'@tSQLt:MyTestAnnotation1Helper'),(2,'@tSQLt:MyTestAnnotation2Helper'),(3,'@tSQLt:MyTestAnnotation3Helper');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test reports meaningful error if annotation line has a lonely single quote]
AS
BEGIN
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return an annotation with a single quote anywhere on line]';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Annotation has unmatched quote: tSQLt.[@tSQLt:Annotation](''aa)', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test reports no error if annotation line has matched quotes]
AS
BEGIN

  EXEC('CREATE FUNCTION tSQLt.[@tSQLt:MyTestAnnotation](@param NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT ''DECLARE @x XML;'' AS AnnotationCmd;');

  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return an annotation with an even number of quotes anywhere on line]';
  
  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test reports error if annotation line has an odd number of quotes]
AS
BEGIN

  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return an annotation with an odd number of quotes anywhere on line]';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Annotation has unmatched quote: tSQLt.[@tSQLt:MyTestAnnotation](''aa'',''bb'',''cc)', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test reports unmatched quote error for correct annotation]
AS
BEGIN

  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return several test Annotations with unmatched quotes]';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Annotation has unmatched quote: tSQLt.[@tSQLt:MyTestAnnotation2](''bb'',''cc)', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;
END;
GO




