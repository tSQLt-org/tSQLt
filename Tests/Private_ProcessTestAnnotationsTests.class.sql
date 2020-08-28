EXEC tSQLt.NewTestClass 'Private_ProcessTestAnnotationsTests';
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return MyTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation]' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:AnotherTestAnnotation]' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return 3 Test Annotations](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation1]' Annotation
  UNION ALL 
  SELECT 2 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation2]' Annotation
  UNION ALL 
  SELECT 3 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation3]' Annotation;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation]';
    EXEC('CREATE PROC tSQLt.[@tSQLt:AnotherTestAnnotation] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:AnotherTestAnnotation]';
END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations
  @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation1] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation1]', @CommandToExecute = @CommandToExecute;
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation2] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation2]', @CommandToExecute = @CommandToExecute;
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation3] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation3]', @CommandToExecute = @CommandToExecute;
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

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:MyTestAnnotation_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls another annotation procedure]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:AnotherTestAnnotation_SpyProcedureLog];
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
      SELECT 'MyTestAnnotation1' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation1_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation2' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation2_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation3' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation3_SpyProcedureLog]
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
  INSERT INTO #Expected VALUES(1,'@tSQLt:MyTestAnnotation1'),(2,'@tSQLt:MyTestAnnotation2'),(3,'@tSQLt:MyTestAnnotation3');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
-- [InvalidAnnotation] missing ]
-- [InvalidAnnotation] additional characters (non-WS) after ")"
/*
 * --[@tSQLt:MyTestAnnotation] @SomeParameter=1
 * --[@tSQLt:ATestAnnotationWithoutParameters]
 * --[@tSQLt:SQLServerVersion] @MinVersion=2016, @MaxVersion=2019
 */
-- -------------------+
--                    | (ProcessTestAnnotations)
--                    V
--
-- does annotation that causes problem get identified correctly when there are multiple annotations
-- error message when annotation is followed by other characters
-- 
