IF OBJECT_ID('tSQLt.Private_CleanTemporaryObject') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanTemporaryObject;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CleanTemporaryObject
AS
BEGIN
  DELETE FROM tSQLt.TemporaryObject;
END
---Build-
GO