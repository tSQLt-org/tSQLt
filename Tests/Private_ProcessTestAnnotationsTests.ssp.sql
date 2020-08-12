EXEC tSQLt.NewTestClass 'Private_ProcessTestAnnotationsTests';
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return MyTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation]' Annotation;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.CreateMyTestAnnotation
  @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation]', @CommandToExecute = @CommandToExecute;
END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls annotation procedure]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotation;
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL, @RunTest = NULL;

  SELECT * INTO #Actual FROM tSQLt.[@tSQLt:MyTestAnnotation_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO



-- allow for parameters in ()
-- can handle () or [] within parameter strings
-- brackets within annotation names are valid
-- spaces between ] and ( 
-- [InvalidAnnotation] invalid function name
-- [InvalidAnnotation] valid name that is not an annotation
-- [InvalidAnnotation] missing () at end
-- [InvalidAnnotation] missing ]
-- [InvalidAnnotation] mismatching parameter count
-- [InvalidAnnotation] additional characters (non-WS) after ")"
