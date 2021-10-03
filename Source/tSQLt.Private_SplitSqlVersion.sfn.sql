IF OBJECT_ID('tSQLt.Private_SplitSqlVersion') IS NOT NULL DROP FUNCTION tSQLt.Private_SplitSqlVersion;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_SplitSqlVersion(@ProductVersion NVARCHAR(128))
/* Important: Do not rename the @ProducVersion parameter! */
RETURNS TABLE
AS
RETURN
/* Important: Do not rename the @ProducVersion parameter! */
/*StartSnip*/
SELECT REVERSE(PARSENAME(X.RP,1)) Major,
       REVERSE(PARSENAME(X.RP,2)) Minor, 
       REVERSE(PARSENAME(X.RP,3)) Build,
       REVERSE(PARSENAME(X.RP,4)) Revision
  FROM (SELECT REVERSE(@ProductVersion)) AS X(RP)
/*EndSnip*/
;
/* Important: Do not rename the @ProducVersion parameter! */
GO
---Build-
GO
