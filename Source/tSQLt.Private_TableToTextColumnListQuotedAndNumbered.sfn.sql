IF OBJECT_ID('tSQLt.Private_TableToTextColumnListQuotedAndNumbered') IS NOT NULL DROP FUNCTION tSQLt.Private_TableToTextColumnListQuotedAndNumbered;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_TableToTextColumnListQuotedAndNumbered(
    @tmpObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
    (
      SELECT 
          ',CAST('+
          QUOTENAME(name,'''')+
          ' AS NVARCHAR(MAX)) C'+
          RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4) 
        FROM tempdb.sys.columns 
       WHERE object_id = @tmpObjectId 
       ORDER BY column_id 
       FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)') [ColumnList];
  GO
---Build-
GO
