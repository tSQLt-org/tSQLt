IF OBJECT_ID('tSQLt.Private_InstallationInfo') IS NOT NULL DROP FUNCTION tSQLt.Private_InstallationInfo;
GO
CREATE FUNCTION tSQLt.Private_InstallationInfo()
RETURNS TABLE
AS
RETURN SELECT CAST(NULL AS NUMERIC(10,2)) AS SqlVersion;
GO
