IF OBJECT_ID('tSQLt.Private_ProcessTestAnnotations') IS NOT NULL DROP PROCEDURE tSQLt.Private_ProcessTestAnnotations;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ProcessTestAnnotations
  @TestObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SELECT @Cmd = 
  (
    SELECT 'EXEC '+Annotation+';' 
      FROM tSQLt.Private_ListTestAnnotations(@TestObjectId)
     ORDER BY AnnotationNo
       FOR XML PATH,TYPE
  ).value('.','NVARCHAR(MAX)');

  IF(@Cmd IS NOT NULL)
  BEGIN
    EXEC(@Cmd);
  END;
END;
GO
---Build-