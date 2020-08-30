IF OBJECT_ID('tSQLt.[@tSQLt:MaxSqlMajorVersion]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:MaxSqlMajorVersion];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:MaxSqlMajorVersion](@MaxVersion INT)
RETURNS TABLE
AS
RETURN
  SELECT AF.*
    FROM (SELECT PSSV.Major FROM tSQLt.Private_SqlVersion() AS PSV CROSS APPLY tSQLt.Private_SplitSqlVersion(PSV.ProductVersion) AS PSSV) AV
   CROSS APPLY tSQLt.[@tSQLt:SkipTest]('Maximum required version is '+
                                       CAST(@MaxVersion AS NVARCHAR(MAX))+
                                       ', but current version is '+
                                       CAST(AV.Major AS NVARCHAR(MAX))+'.'
                                      ) AS AF
   WHERE @MaxVersion > AV.Major
GO
---Build-
GO

