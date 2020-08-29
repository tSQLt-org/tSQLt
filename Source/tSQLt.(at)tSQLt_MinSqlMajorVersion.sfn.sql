IF OBJECT_ID('tSQLt.[@tSQLt:MinSqlMajorVersion]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:MinSqlMajorVersion];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:MinSqlMajorVersion](@Version INT)
RETURNS TABLE
AS
RETURN
  SELECT *
    FROM tSQLt.[@tSQLt:SkipTest]('')
   WHERE @Version > (SELECT PSSV.Major FROM tSQLt.Private_SqlVersion() AS PSV CROSS APPLY tSQLt.Private_SplitSqlVersion(PSV.ProductVersion) AS PSSV)
GO
---Build-
GO
