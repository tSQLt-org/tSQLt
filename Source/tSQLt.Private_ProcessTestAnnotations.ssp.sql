IF OBJECT_ID('tSQLt.Private_ProcessTestAnnotations') IS NOT NULL DROP PROCEDURE tSQLt.Private_ProcessTestAnnotations;
GO
---Build+
GO
--[@tSQLt:MyTestAnnotation] @SomeParameter=1
--[@tSQLt:MinSQLServerVersion](2016)
--[@tSQLt:SQLServerVersion] @MinVersion=2016, @MaxVersion=2019
CREATE PROCEDURE tSQLt.Private_ProcessTestAnnotations
  @TestObjectId INT,
  @RunTest BIT OUTPUT
AS
BEGIN
  SET @RunTest = 1;
  DECLARE @Cmd NVARCHAR(MAX);
  SELECT @Cmd = Annotation FROM tSQLt.Private_ListTestAnnotations(@TestObjectId)
  IF(@Cmd IS NOT NULL)
  BEGIN
    SET @Cmd = N'SET @RunTest = '+@Cmd+';'
    PRINT @Cmd;
    EXEC sp_executesql @Cmd,N'@RunTest BIT OUTPUT',@RunTest OUT;
  END;
END;
GO
---Build-