IF OBJECT_ID('tSQLt.Private_TableToTextColumnListMaxLenNumbered') IS NOT NULL DROP FUNCTION tSQLt.Private_TableToTextColumnListMaxLenNumbered;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_TableToTextColumnListMaxLenNumbered(
    @tmpObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
    (
      SELECT 
          ',MAX(LEN(C'+
          RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4)+
          ')) L'+
          RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4)
        FROM tempdb.sys.columns 
      WHERE object_id = @tmpObjectId 
      ORDER BY column_id 
      FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)') [ColumnList];
  GO
---Build-
GO
