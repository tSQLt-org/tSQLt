IF OBJECT_ID('tSQLt.Info') IS NOT NULL DROP FUNCTION tSQLt.Info;
-- This will not work if executed outside of the build!
GO
---Build+
GO
CREATE FUNCTION tSQLt.Info()
RETURNS TABLE
AS
RETURN
SELECT Version = '$LATEST-BUILD-NUMBER$',
       ClrVersion = (SELECT tSQLt.Private::Info()),
       ClrSigningKey = (SELECT tSQLt.Private::SigningKey()),
       V.SqlVersion,
       V.SqlBuild,
       V.SqlEdition,
       V.HostPlatform
  FROM
  (
    SELECT CAST(PSSV.Major+'.'+PSSV.Minor AS NUMERIC(10,2)) AS SqlVersion,
           CAST(PSSV.Build+'.'+PSSV.Revision AS NUMERIC(10,2)) AS SqlBuild,
           PSV.Edition AS SqlEdition,
           PHP.host_platform AS HostPlatform
          FROM tSQLt.Private_SqlVersion() AS PSV
         CROSS APPLY tSQLt.Private_SplitSqlVersion(PSV.ProductVersion) AS PSSV
         CROSS JOIN tSQLt.Private_HostPlatform AS PHP
  )V;
GO
---Build-
GO
SELECT * FROM tSQLt.Info() AS I;
