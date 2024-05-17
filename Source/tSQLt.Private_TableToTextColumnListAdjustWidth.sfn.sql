IF OBJECT_ID('tSQLt.Private_TableToTextColumnListAdjustWidth') IS NOT NULL DROP FUNCTION tSQLt.Private_TableToTextColumnListAdjustWidth;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_TableToTextColumnListAdjustWidth(
    @tmpObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
    (
      SELECT 
          ',C'+NN+' = CASE WHEN LEN(C.C'+NN+')>L.MCW '+
          'THEN LEFT(C.C'+NN+',(L.MCW-5)/2)+''<...>''+RIGHT(C.C'+NN+',(L.MCW-5)/2) '+
          'ELSE LEFT(C.C'+NN+'+REPLICATE('' '','+
                                'CASE WHEN L.MCW < L.L'+NN+' '+
                                'THEN L.MCW ELSE L.L'+NN+' END - '+
                                'LEN(C.C'+NN+')),'+
                                'CASE WHEN L.MCW < L.L'+NN+' '+
                                'THEN L.MCW ELSE L.L'+NN+' END) '+
          'END'
        FROM(
          SELECT 
              column_id,RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4) NN
            FROM sys.columns 
           WHERE object_id = @tmpObjectId 
             AND column_id>1
        )X
       ORDER BY column_id 
      FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)') [ColumnList];
  GO
---Build-
GO
--+REPLICATE(' ',LEN(C'+NN+'))
--',C'+NN+' = CASE WHEN LEN(C'+NN+')>L.MCW THEN LEFT(C'+NN+',(L.MCW-5)/2)+''<...>''+RIGHT(C'+NN+',(L.MCW-5)/2) ELSE LEFT(C'+NN+'+REPLICATE(' ',CASE WHEN L.MCW < L.L'+NN+' THEN L.MCW ELSE L.L'+NN+' END - LEN(C'+NN+')),9) END'