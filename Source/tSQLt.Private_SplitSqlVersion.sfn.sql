IF OBJECT_ID('tSQLt.Private_SplitSqlVersion') IS NOT NULL DROP FUNCTION tSQLt.Private_SplitSqlVersion;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_SplitSqlVersion(@ProductVersion NVARCHAR(128))
RETURNS TABLE
AS
RETURN
  SELECT PARSENAME(@ProductVersion,4) Major,
         PARSENAME(@ProductVersion,3) Minor, 
         PARSENAME(@ProductVersion,2) Build,
         PARSENAME(@ProductVersion,1) Revision;
GO
---Build-
GO
