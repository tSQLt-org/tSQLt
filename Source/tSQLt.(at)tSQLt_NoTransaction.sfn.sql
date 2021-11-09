IF OBJECT_ID('tSQLt.[@tSQLt:NoTransaction]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:NoTransaction];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:NoTransaction]()
RETURNS TABLE
AS
RETURN
  SELECT NULL AS AnnotationCmd;
GO
---Build-
GO
