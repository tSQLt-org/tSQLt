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
    SELECT 
       'BEGIN TRY;EXEC '+
       Annotation+
       ';END TRY BEGIN CATCH;DECLARE @EM NVARCHAR(MAX)=ERROR_MESSAGE(),@ES INT=ERROR_SEVERITY(),'+
       '@ET INT=ERROR_STATE(),@EP NVARCHAR(MAX)=QUOTENAME(ERROR_PROCEDURE());'+
       'RAISERROR(''There is a problem with this annotation: %s'+CHAR(13)+CHAR(10)+'Original Error: {%i,%i;%s}%s'',16,10,'''+
       SUBSTRING(Annotation,7,LEN(Annotation))+
       ''',@ES,@ET,@EP,@EM);END CATCH;' 
      FROM tSQLt.Private_ListTestAnnotations(@TestObjectId)
     ORDER BY AnnotationNo
       FOR XML PATH,TYPE
  ).value('.','NVARCHAR(MAX)');

  IF(@Cmd IS NOT NULL)
  BEGIN
  SELECT * FROM tSQLt.Private_ListTestAnnotations(@TestObjectId);
  RAISERROR(@Cmd,0,1)WITH NOWAIT;
    EXEC(@Cmd);
  END;
END;
GO
---Build-