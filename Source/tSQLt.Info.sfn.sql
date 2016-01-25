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
    SELECT CAST(VI.major+'.'+VI.minor AS NUMERIC(10,2)) AS SqlVersion,
           CAST(VI.build+'.'+VI.revision AS NUMERIC(10,2)) AS SqlBuild,
           SqlEdition
      FROM
      (
        SELECT PARSENAME(PSV.ProductVersion,4) major,
               PARSENAME(PSV.ProductVersion,3) minor, 
               PARSENAME(PSV.ProductVersion,2) build,
               PARSENAME(PSV.ProductVersion,1) revision,
               Edition AS SqlEdition
          FROM tSQLt.Private_SqlVersion() AS PSV
      )VI
  )V;
---Build-
