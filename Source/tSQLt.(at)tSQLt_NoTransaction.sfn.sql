IF OBJECT_ID('tSQLt.[@tSQLt:NoTransaction]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:NoTransaction];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:NoTransaction](@CleanUpProcedureName NVARCHAR(MAX) = NULL)
RETURNS TABLE
AS
RETURN
  SELECT
      'IF(OBJECT_ID('+X.QuotedName+') IS NULL) BEGIN RAISERROR(''sss'',16,10); END;'+
    'INSERT INTO #NoTransaction VALUES('+X.QuotedName+');' AS AnnotationCmd
    FROM (VALUES(''''+REPLACE(@CleanUpProcedureName,'''','''''')+''''))X(QuotedName);
GO
---Build-
GO
