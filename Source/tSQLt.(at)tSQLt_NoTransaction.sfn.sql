IF OBJECT_ID('tSQLt.[@tSQLt:NoTransaction]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:NoTransaction];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:NoTransaction](@CleanUpProcedureName NVARCHAR(MAX) = NULL)
RETURNS TABLE
AS
RETURN
  SELECT
    CASE 
      WHEN (X.QuotedName IS NULL) 
        THEN 'INSERT INTO #NoTransaction VALUES(NULL);'
      ELSE 'IF(NOT EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('+X.QuotedName+'))) BEGIN RAISERROR(''Test CleanUp Procedure %s does not exist or is not a procedure.'',16,10,'+X.QuotedName+'); END;INSERT INTO #NoTransaction VALUES('+X.QuotedName+');'
    END AS AnnotationCmd
    FROM (VALUES(''''+REPLACE(@CleanUpProcedureName,'''','''''')+''''))X(QuotedName);
GO
---Build-
GO
