IF OBJECT_ID('tSQLt.Private_ProcessTestAnnotations') IS NOT NULL DROP PROCEDURE tSQLt.Private_ProcessTestAnnotations;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ProcessTestAnnotations
  @TestObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  CREATE TABLE #AnnotationCommands(AnnotationOrderNo INT, AnnotationCmd NVARCHAR(MAX));
  SELECT @Cmd = 
    'DECLARE @EM NVARCHAR(MAX),@ES INT,@ET INT,@EP NVARCHAR(MAX);'+
    (
      SELECT 
         'BEGIN TRY;INSERT INTO #AnnotationCommands SELECT '+CAST(AnnotationNo AS NVARCHAR(MAX))+',A.AnnotationCmd FROM '+
         Annotation+' AS A;'+
         ';END TRY BEGIN CATCH;'+
         'SELECT @EM=REPLACE(ERROR_MESSAGE(),'''''''',''''''''''''),'+
                '@ES=ERROR_SEVERITY(),'+
                '@ET=ERROR_STATE(),'+
                '@EP=QUOTENAME(ERROR_PROCEDURE());'+
         'RAISERROR(''There is a problem with this annotation: %s'+CHAR(13)+CHAR(10)+
                    'Original Error: {%i,%i;%s} %s'',16,10,'''+
                    REPLACE(SUBSTRING(Annotation,7,LEN(Annotation)),'''','''''')+
                    ''',@ES,@ET,@EP,@EM);'+
         'END CATCH;' 
        FROM tSQLt.Private_ListTestAnnotations(@TestObjectId)
       ORDER BY AnnotationNo
         FOR XML PATH,TYPE
    ).value('.','NVARCHAR(MAX)');

  IF(@Cmd IS NOT NULL)
  BEGIN
  --PRINT '--------------------------------';
  --PRINT @Cmd
  --PRINT '--------------------------------';
    EXEC(@Cmd);


    SELECT @Cmd = 
    'DECLARE @EM NVARCHAR(MAX),@ES INT,@ET INT,@EP NVARCHAR(MAX);'+
    (
      SELECT 
         'BEGIN TRY;'+
         AnnotationCmd+
         ';END TRY BEGIN CATCH;'+
         'SELECT @EM=REPLACE(ERROR_MESSAGE(),'''''''',''''''''''''),'+
                '@ES=ERROR_SEVERITY(),'+
                '@ET=ERROR_STATE(),'+
                '@EP=QUOTENAME(ERROR_PROCEDURE());'+
         'RAISERROR(''There is a problem with this annotation: %s'+CHAR(13)+CHAR(10)+
                    'Original Error: {%i,%i;%s} %s'',16,10,'''+
                    REPLACE(SUBSTRING(AnnotationCmd,7,LEN(AnnotationCmd)),'''','''''')+
                    ''',@ES,@ET,@EP,@EM);'+
         'END CATCH;' 
        FROM #AnnotationCommands
       ORDER BY AnnotationOrderNo
         FOR XML PATH,TYPE
    ).value('.','NVARCHAR(MAX)');

    IF(@Cmd IS NOT NULL)
    BEGIN
    --PRINT '--------------------------------';
    --PRINT @Cmd
    --PRINT '--------------------------------';
      EXEC(@Cmd);
    END;

  END;

END;
GO
---Build-