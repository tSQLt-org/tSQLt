IF OBJECT_ID('tSQLt.FriendlySQLServerVersion') IS NOT NULL DROP FUNCTION tSQLt.FriendlySQLServerVersion;
GO
CREATE FUNCTION tSQLt.FriendlySQLServerVersion(@ProductVersion NVARCHAR(128))
RETURNS TABLE
AS
RETURN
  SELECT CASE WHEN SSV.Major = '15' THEN '2019' END FriendlyVersion
    FROM tSQLt.Private_SplitSqlVersion(@ProductVersion) AS SSV;
GO
