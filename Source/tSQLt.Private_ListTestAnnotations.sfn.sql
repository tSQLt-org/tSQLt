IF OBJECT_ID('tSQLt.Private_ListTestAnnotations') IS NOT NULL DROP FUNCTION tSQLt.Private_ListTestAnnotations;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_ListTestAnnotations(
  @TestObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
      GAL.AnnotationNo,
      REPLACE(GAL.Annotation,'''','''''') AS QuotedAnnotationString,
      'tSQLt.'+GAL.Annotation AS Annotation
    FROM tSQLt.Private_GetAnnotationList(OBJECT_DEFINITION(@TestObjectId))AS GAL;
GO
---Build-
GO
