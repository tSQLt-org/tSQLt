IF OBJECT_ID('tSQLt.FriendlySQLServerVersion') IS NOT NULL DROP FUNCTION tSQLt.FriendlySQLServerVersion;
GO
---Build+
GO
CREATE FUNCTION tSQLt.FriendlySQLServerVersion(@ProductVersion NVARCHAR(128))
/* Important: Do not rename the @ProducVersion parameter! */
RETURNS TABLE
AS
RETURN
/* Important: Do not rename the @ProducVersion parameter! */
/*StartSnip*/
  SELECT 
      @ProductVersion ProductVersion, 
      CASE 
        WHEN SSV.Major = '15' THEN '2019' 
        WHEN SSV.Major = '14' THEN '2017' 
        WHEN SSV.Major = '13' THEN '2016' 
        WHEN SSV.Major = '12' THEN '2014' 
        WHEN SSV.Major = '11' THEN '2012' 
        WHEN SSV.Major = '10' AND SSV.Minor IN ('50','5') THEN '2008R2' 
        WHEN SSV.Major = '10' AND SSV.Minor IN ('00','0') THEN '2008' 
       END FriendlyVersion
/*EndSnip*/
/* Important: Do not rename the @ProducVersion parameter! */
    FROM tSQLt.Private_SplitSqlVersion(@ProductVersion) AS SSV;
GO
---Build-
GO