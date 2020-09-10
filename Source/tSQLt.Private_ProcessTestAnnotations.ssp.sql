IF OBJECT_ID('tSQLt.Private_ProcessTestAnnotations') IS NOT NULL DROP PROCEDURE tSQLt.Private_ProcessTestAnnotations;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ProcessTestAnnotations
  @TestObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  DECLARE @UnmatchedQuotesAnnotation NVARCHAR(MAX);
  CREATE TABLE #AnnotationCommands(AnnotationOrderNo INT, AnnotationString NVARCHAR(MAX), AnnotationCmd NVARCHAR(MAX));

  SELECT * INTO #AnnotationList FROM tSQLt.Private_ListTestAnnotations(@TestObjectId);
  SET @UnmatchedQuotesAnnotation = NULL;
  SELECT TOP(1) @UnmatchedQuotesAnnotation = AL.Annotation 
    FROM #AnnotationList AS AL 
   WHERE (LEN(AL.Annotation ) - LEN(REPLACE(AL.Annotation, '''', '')))%2=1
   ORDER BY AL.AnnotationNo;

  IF(@UnmatchedQuotesAnnotation IS NOT NULL)
  BEGIN
    RAISERROR('Annotation has unmatched quote: %s',16,10,@UnmatchedQuotesAnnotation);
  END;

  SELECT @Cmd = 
    'DECLARE @EM NVARCHAR(MAX),@ES INT,@ET INT,@EP NVARCHAR(MAX);'+
    (
      SELECT 
         'BEGIN TRY;INSERT INTO #AnnotationCommands '+
                'SELECT '+
                 CAST(AL.AnnotationNo AS NVARCHAR(MAX))+','+
                 ''''+AL.EscapedAnnotationString+''''+
                 ',A.AnnotationCmd FROM '+
         AL.Annotation+' AS A;'+
         ';END TRY BEGIN CATCH;'+
         'SELECT @EM=ERROR_MESSAGE(),'+--REPLACE(ERROR_MESSAGE(),'''''''',''''''''''''),'+
                '@ES=ERROR_SEVERITY(),'+
                '@ET=ERROR_STATE();'+
         'RAISERROR(''There is an internal error for annotation: %s'+CHAR(13)+CHAR(10)+
                    '  caused by {%i,%i} %s'',16,10,'''+
                    AL.EscapedAnnotationString+
                    ''',@ES,@ET,@EM);'+
         'END CATCH;' 
        FROM #AnnotationList AS AL
       ORDER BY AL.AnnotationNo
         FOR XML PATH,TYPE
    ).value('.','NVARCHAR(MAX)');

  IF(@Cmd IS NOT NULL)
  BEGIN
  --PRINT '--------------------------------';
  --PRINT @Cmd
  --PRINT '--------------------------------';
  BEGIN TRY
    EXEC(@Cmd);
  END TRY
  BEGIN CATCH
    DECLARE @EM NVARCHAR(MAX),@ES INT,@ET INT,@EP NVARCHAR(MAX);
    SELECT @EM=REPLACE(ERROR_MESSAGE(),'''',''''''),
           @ES=ERROR_SEVERITY(),
           @ET=ERROR_STATE();
    DECLARE @NewErrorMessage NVARCHAR(MAX)=
              'There is a problem with the annotations:'+CHAR(13)+CHAR(10)+
              'Original Error: {%i,%i} %s'
    RAISERROR(@NewErrorMessage,16,10,@ES,@ET,@EM);
  END CATCH;
  --PRINT '--------------------------------';


    SELECT @Cmd = 
    'DECLARE @EM NVARCHAR(MAX),@ES INT,@ET INT,@EP NVARCHAR(MAX);'+
    (
      SELECT 
         'BEGIN TRY;'+
         AnnotationCmd+
         ';END TRY BEGIN CATCH;'+
         'SELECT @EM=ERROR_MESSAGE(),'+--REPLACE(ERROR_MESSAGE(),'''''''',''''''''''''),'+
                '@ES=ERROR_SEVERITY(),'+
                '@ET=ERROR_STATE(),'+
                '@EP=ERROR_PROCEDURE();'+
         'RAISERROR(''There is a problem with this annotation: %s'+CHAR(13)+CHAR(10)+
                    'Original Error: {%i,%i;%s} %s'',16,10,'''+
                    REPLACE(AnnotationString,'''','''''')+
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