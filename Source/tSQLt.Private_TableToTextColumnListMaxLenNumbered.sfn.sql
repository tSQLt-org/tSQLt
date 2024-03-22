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
          ',MAX(LEN(''.''+C'+
          RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4)+
          '+''.''))-2 L'+
          RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4)
        FROM sys.columns 
      WHERE object_id = @tmpObjectId 
        AND column_id>1
      ORDER BY column_id 
      FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)') [ColumnList];
  GO
---Build-
GO
