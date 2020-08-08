EXEC tSQLt.NewTestClass 'Private_ListTestAnnotationsTests';
GO
CREATE PROCEDURE Private_ListTestAnnotationsTests.[test finds a simple annotation]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'--[@tSQLt:MyAnnotation]()
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_ListTestAnnotations(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('[@tSQLt:MyAnnotation]()');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
