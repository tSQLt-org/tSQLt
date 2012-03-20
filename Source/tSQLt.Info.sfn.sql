IF OBJECT_ID('tSQLt.Info') IS NOT NULL DROP FUNCTION tSQLt.Info;
GO
---Build+
CREATE FUNCTION tSQLt.Info()
RETURNS TABLE
AS
RETURN
SELECT
Version = '$LATEST-BUILD-NUMBER$',
ClrVersion = (SELECT tSQLt.Private::Info());
---Build-
