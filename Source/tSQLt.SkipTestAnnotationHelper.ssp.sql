IF OBJECT_ID('tSQLt.SkipTestAnnotationHelper') IS NOT NULL DROP PROCEDURE tSQLt.SkipTestAnnotationHelper;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.SkipTestAnnotationHelper
  @SkipReason NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO #SkipTest VALUES(@SkipReason);
END;
GO
---Build-
GO