IF OBJECT_ID('tSQLt.[@tSQLt:RunOnlyOnHostPlatform]') IS NOT NULL DROP FUNCTION tSQLt.[@tSQLt:RunOnlyOnHostPlatform];
GO
---Build+
GO
CREATE FUNCTION tSQLt.[@tSQLt:RunOnlyOnHostPlatform](@HostPlatform NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT SkipTestFunction.*
    FROM (SELECT PSV.HostPlatform FROM tSQLt.Private_SqlVersion() AS PSV WHERE PSV.HostPlatform <> @HostPlatform) AV
   CROSS APPLY tSQLt.[@tSQLt:SkipTest]('HostPlatform is required to be '''+
                                       @HostPlatform +
                                       ''', but is '''+
                                       AV.HostPlatform +
                                       '''.'
                                      ) AS SkipTestFunction;
GO
---Build-
GO

