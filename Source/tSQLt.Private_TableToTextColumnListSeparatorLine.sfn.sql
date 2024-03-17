IF OBJECT_ID('tSQLt.Private_TableToTextColumnListSeparatorLine') IS NOT NULL DROP FUNCTION tSQLt.Private_TableToTextColumnListSeparatorLine;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_TableToTextColumnListSeparatorLine(
    @tmpObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
    (
      SELECT 
          ',REPLICATE(''-'','+
                        'CASE WHEN L.MCW < L.L'+NN+' '+
                        'THEN L.MCW ELSE L.L'+NN+' END)'
        FROM(
          SELECT 
              column_id,RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4) NN
            FROM tempdb.sys.columns 
           WHERE object_id = @tmpObjectId 
        )X
       ORDER BY column_id 
      FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)') [ColumnList];
  GO
---Build-
GO
--+REPLICATE(' ',LEN(C'+NN+'))
--',C'+NN+' = CASE WHEN LEN(C'+NN+')>L.MCW THEN LEFT(C'+NN+',(L.MCW-5)/2)+''<...>''+RIGHT(C'+NN+',(L.MCW-5)/2) ELSE LEFT(C'+NN+'+REPLICATE(' ',CASE WHEN L.MCW < L.L'+NN+' THEN L.MCW ELSE L.L'+NN+' END - LEN(C'+NN+')),9) END'