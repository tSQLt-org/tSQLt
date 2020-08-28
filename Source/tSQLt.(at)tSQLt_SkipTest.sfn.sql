IF OBJECT_ID('tSQLt.[@tSQLt:SkipTest]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:SkipTest];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:SkipTest](@SkipReason NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT 'EXEC tSQLt.SkipTestAnnotationHelper @SkipReason = '''+REPLACE(@SkipReason,'''','''''')+''';' AS AnnotationCmd;
GO
---Build-
GO
