IF OBJECT_ID('tSQLt.Private_ProcessTestAnnotations') IS NOT NULL DROP PROCEDURE tSQLt.Private_ProcessTestAnnotations;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ProcessTestAnnotations
  @TestObjectId INT,
  @RunTest BIT OUTPUT
AS
BEGIN
  SET @RunTest = 1;
  IF(EXISTS(
    SELECT 1 
      FROM sys.sql_modules AS SM 
     WHERE SM.object_id = @TestObjectId 
       AND SM.definition LIKE '%--_@tSQLt:MyTestAnnotation_()%'
    )
  )
  BEGIN
    EXEC sp_executesql N'SET @RunTest = tSQLt.[@tSQLt:MyTestAnnotation]();',N'@RunTest Bit OUTPUT',@RunTest OUT;
  END;
END;
GO
---Build-