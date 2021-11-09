IF OBJECT_ID('tSQLt.[@tSQLt:MinSqlMajorVersion]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:MinSqlMajorVersion];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:MinSqlMajorVersion](@MinVersion INT)
RETURNS TABLE
AS
RETURN
  SELECT AF.*
    FROM
    (
      SELECT PSSV.Major
        FROM tSQLt.Private_SqlVersion() AS PSV
       CROSS APPLY tSQLt.Private_SplitSqlVersion(PSV.ProductVersion) AS PSSV
    ) AV
   CROSS APPLY tSQLt.[@tSQLt:SkipTest]('Minimum required version is '+
                                       CAST(@MinVersion AS NVARCHAR(MAX))+
                                       ', but current version is '+
                                       CAST(AV.Major AS NVARCHAR(MAX))+'.'
                                      ) AS AF
   WHERE @MinVersion > AV.Major
GO
---Build-
GO

