EXEC tSQLt.NewTestClass 'Private_GetAnnotationListTests';
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test returns empty result if there's no annotaion]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test finds a simple annotation and returns it without --]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation]
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('[@tSQLt:MyAnnotation]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test annotation is ignored if there are additional non-space characters in front of --]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'X-'+'-[@tSQLt:MyAnnotation]
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test annotation is valid if there are spaces in front of --]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'  -'+'-[@tSQLt:MyAnnotation]
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES('[@tSQLt:MyAnnotation]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test annotation is valid if there are tabs in front of --]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
NCHAR(9)+'-'+'-[@tSQLt:MyAnnotation]
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES('[@tSQLt:MyAnnotation]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test removes trailing spaces]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation]  '+'
CREATE...'
  SELECT '>>>'+Annotation+'<<<' AS BracketedAnnotation, LEN(Annotation) AnnotationLength 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES('>>>[@tSQLt:MyAnnotation]<<<',21);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test removes trailing tabs]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation]'+NCHAR(9)+'
CREATE...'
  SELECT '>>>'+Annotation+'<<<' AS BracketedAnnotation, LEN(Annotation) AnnotationLength  
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES('>>>[@tSQLt:MyAnnotation]<<<',21);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test returns all annotations]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation1]
-'+'-[@tSQLt:MyAnnotation2]
-'+'-[@tSQLt:MyAnnotation3]
CREATE...'
  SELECT Annotation
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES
    ('[@tSQLt:MyAnnotation1]'),
    ('[@tSQLt:MyAnnotation2]'),
    ('[@tSQLt:MyAnnotation3]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test returns annotations with order number based on where they appear]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation1]
-'+'-[@tSQLt:MyAnnotation3]
-'+'-[@tSQLt:MyAnnotation2]
CREATE...'
  SELECT AnnotationNo,Annotation
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES
    (1,'[@tSQLt:MyAnnotation1]'),
    (2,'[@tSQLt:MyAnnotation3]'),
    (3,'[@tSQLt:MyAnnotation2]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test returns annotations anywhere in the code (as long as they are on their own line)]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'CREATE PROCEDURE dbo.something
-'+'-[@tSQLt:MyAnnotation1]
AS
BEGIN
SELECT Something
-'+'-[@tSQLt:MyAnnotation2]
FROM dbo.sometable
-'+'-[@tSQLt:MyAnnotation3]
WHERE 0=1;
-'+'-[@tSQLt:MyAnnotation4]
RETURN 0;
-'+'-[@tSQLt:MyAnnotation5]
END;
-'+'-[@tSQLt:MyAnnotation6]';

  SELECT Annotation
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected
  VALUES
    ('[@tSQLt:MyAnnotation1]'),
    ('[@tSQLt:MyAnnotation2]'),
    ('[@tSQLt:MyAnnotation3]'),
    ('[@tSQLt:MyAnnotation4]'),
    ('[@tSQLt:MyAnnotation5]'),
    ('[@tSQLt:MyAnnotation6]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test return full line with all parameters]
AS
BEGIN
  DECLARE @proc NVARCHAR(MAX) =
'-'+'-[@tSQLt:MyAnnotation] ''some string'',123,''string with ()'',''string with []'',''@'',''-'+'-[@tSQLt:MyAnnotation]'' --this is still invalid
CREATE...'
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(@proc);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('[@tSQLt:MyAnnotation] ''some string'',123,''string with ()'',''string with []'',''@'',''-'+'-[@tSQLt:MyAnnotation]'' --this is still invalid');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_GetAnnotationListTests.[test returns empty result if @ProcedureDefinition IS NULL]
AS
BEGIN
  SELECT Annotation 
    INTO #Actual
    FROM tSQLt.Private_GetAnnotationList(NULL);
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO


