IF OBJECT_ID('tSQLt.Private_SkipTestAnnotationHelper') IS NOT NULL DROP PROCEDURE tSQLt.Private_SkipTestAnnotationHelper;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_SkipTestAnnotationHelper
  @SkipReason NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO #SkipTest VALUES(@SkipReason);
END;
GO
---Build-
GO