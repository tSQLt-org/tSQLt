IF OBJECT_ID('tSQLt.Private_TableToTextColumntoStringList') IS NOT NULL DROP FUNCTION tSQLt.Private_TableToTextColumntoStringList;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_TableToTextColumntoStringList(
    @tmpObjectId INT
)
RETURNS TABLE
AS
RETURN
  SELECT 
    (
      SELECT 
          ',ISNULL('+
            CASE 
              WHEN type_name = 'DATETIME' THEN 'CONVERT(NVARCHAR(MAX),'+QUOTENAME(name)+',121)'
              WHEN type_name = 'SMALLDATETIME' THEN 'CONVERT(NVARCHAR(16),'+QUOTENAME(name)+',121)'
              WHEN type_name = 'FLOAT' THEN 'UPPER(CONVERT(NVARCHAR(MAX),'+QUOTENAME(name)+',2))'
              WHEN type_name = 'IMAGE' THEN 'CONVERT(NVARCHAR(MAX),CAST('+QUOTENAME(name)+' AS VARBINARY(MAX)),1)'
              WHEN type_name IN ('BINARY','VARBINARY') THEN 'CONVERT(NVARCHAR(MAX),'+QUOTENAME(name)+',1)'
              WHEN type_name = 'UNIQUEIDENTIFIER' THEN 'LOWER(CONVERT(NVARCHAR(MAX),'+QUOTENAME(name)+'))'
              WHEN type_name = 'TIMESTAMP' THEN 'CONVERT(NVARCHAR(MAX),CAST('+QUOTENAME(name)+' AS VARBINARY(MAX)),1)'
              ELSE 'CAST('+QUOTENAME(name)+' AS NVARCHAR(MAX))'
            END+
          ',''!NULL!'')'
        FROM(
          SELECT 
              C.column_id,TS.name type_name,C.name
            FROM tempdb.sys.columns C
            JOIN tempdb.sys.types TU
              ON TU.user_type_id = C.user_type_id
            JOIN tempdb.sys.types TS
              ON TS.user_type_id = TU.system_type_id
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