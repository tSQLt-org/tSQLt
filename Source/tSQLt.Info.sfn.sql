IF OBJECT_ID('tSQLt.Info') IS NOT NULL DROP FUNCTION tSQLt.Info;
GO
---Build+
CREATE FUNCTION tSQLt.Info()
RETURNS TABLE
AS
RETURN
SELECT Version = '$LATEST-BUILD-NUMBER$',
       ClrVersion = (SELECT tSQLt.Private::Info()),
       ClrSigningKey = (SELECT tSQLt.Private::SigningKey()),
       V.SqlVersion,
       V.SqlBuild,
       V.SqlEdition
  FROM
  (
    SELECT CAST(PSV.Major+'.'+PSV.Minor AS NUMERIC(10,2)) AS SqlVersion,
           CAST(PSV.Build+'.'+PSV.Revision AS NUMERIC(10,2)) AS SqlBuild,
           PSV.Edition AS SqlEdition
      FROM tSQLt.Private_SqlVersion() AS PSV
  )V;
---Build-
