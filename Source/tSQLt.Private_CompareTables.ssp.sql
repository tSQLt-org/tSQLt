IF OBJECT_ID('tSQLt.Private_CompareTables') IS NOT NULL DROP PROCEDURE tSQLt.Private_CompareTables;
GO
---BUILD+
CREATE PROCEDURE tSQLt.Private_CompareTables
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @ResultTable NVARCHAR(MAX),
    @ColumnList NVARCHAR(MAX),
    @MatchIndicatorColumnName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    DECLARE @RestoredRowIndexCounterColName NVARCHAR(MAX);
    SET @RestoredRowIndexCounterColName = @MatchIndicatorColumnName + '_RR';
    
    SELECT @cmd = 
    '
    INSERT INTO ' + @ResultTable + '
    SELECT 
      CASE 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= CASE WHEN [_{Left}_]<[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END
         THEN ''='' 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= [_{Left}_] 
         THEN ''<'' 
        ELSE ''>'' 
      END AS ' + @MatchIndicatorColumnName + ', ' + @ColumnList + '
    FROM(
      SELECT MAX([_{Left}_]) AS [_{Left}_], 
             MAX([_{Right}_]) AS [_{Right}_], 
             ' + @ColumnList + ' 
      FROM (
        SELECT COUNT(1) AS [_{Left}_], 0[_{Right}_], ' + @ColumnList + '
          FROM ' + @Expected + '
         GROUP BY ' + @ColumnList + ' 
        UNION ALL 
        SELECT 0[_{Left}_], COUNT(1) AS [_{Right}_], ' + @ColumnList + ' 
          FROM ' + @Actual + '
         GROUP BY ' + @ColumnList + ' 
      ) AS X 
      GROUP BY ' + @ColumnList + ' 
    ) AS CollapsedRows
    CROSS APPLY (SELECT TOP(CASE WHEN [_{Left}_]>[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END) ROW_NUMBER()OVER(ORDER BY(SELECT 1)) FROM '+@Actual+') AS RestoredRowIndex('+@RestoredRowIndexCounterColName+');';
--TODO:                                                                                                         need to create enough rows here --^
--  Test: use SUM([_{Left}_])[_{Left}_],SUM([_{Right}_])[_{Right}_] with single GROUP BY instead of three GROUP BY statements
--  Test: Use window aggregate instead of agregate followed by join
--  Test: Use 1[_{Left}_], 0[_{Right}_],ROW_NUMBER()OVER(PARTITION BY' + @ColumnList + ' ORDER BY (SELECT 1)) [_{RowNumber}_]
--  Test: Using a #tbl instead of a @tbl in AssertEqualsTable might be faster?
--
--  Change [_{xxx}_] into [_{xxx}_' + @ResultTable + ']
--Should @ResultTable contain the schema name?
--
--Performance Testing Material at the end of this file
--
--Old version:
--    CROSS APPLY (SELECT * FROM tSQLt.F_Num(CASE WHEN [_{Left}_]>[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END)) AS RestoredRowIndex('+@RestoredRowIndexCounterColName+');';
    
    EXEC (@cmd);
    
    SET @cmd = 'SET @r = 
         CASE WHEN EXISTS(
                  SELECT 1 
                    FROM ' + @ResultTable + 
                 ' WHERE ' + @MatchIndicatorColumnName + ' IN (''<'', ''>'')) 
              THEN 1 ELSE 0 
         END';
    DECLARE @UnequalRowsExist INT;
    EXEC sp_executesql @cmd, N'@r INT OUTPUT',@UnequalRowsExist OUTPUT;
    
    RETURN @UnequalRowsExist;
END;
---Build-







/*--Performance Testing Material...



IF OBJECT_ID('A') IS NOT NULL DROP TABLE A;
IF OBJECT_ID('B') IS NOT NULL DROP TABLE B;

CREATE TABLE A (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);
CREATE TABLE B (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);

INSERT INTO A (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (2, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (3, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);

INSERT INTO B (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (7, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (3, 'ewqfwef', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);


--SET STATISTICS TIME ON;
DECLARE @cntr INT = 0;
WHILE @cntr < 1000
BEGIN
  SET @cntr = @cntr + 1;
  EXEC tSQLt.AssertEqualsTable 'A', 'B';
END;

--SET STATISTICS TIME OFF;


--SELECT DB_ID()
SELECT 
Duration,CPU,Reads,CAST(TextData AS NVARCHAR(MAX)) TextData
INTO tempdb.dbo.trc4
FROM tempdb..trc3

SELECT TOP(10)* FROM(
SELECT COUNT(1) Cnt,AVG(Duration) ADur,AVG(CPU)ACPU,AVG(Reads)AReads,CAST(TextData AS NVARCHAR(MAX)) TextData
FROM tempdb..trc2
GROUP BY CAST(TextData AS NVARCHAR(MAX))
HAVING COUNT(1)>1
)x
ORDER BY ACPU DESC, AReads DESC
SELECT TOP(10)* FROM(
SELECT COUNT(1) Cnt,AVG(Duration) ADur,AVG(CPU)ACPU,AVG(Reads)AReads,CAST(TextData AS NVARCHAR(MAX)) TextData
FROM tempdb..trc4
GROUP BY CAST(TextData AS NVARCHAR(MAX))
HAVING COUNT(1)>1
)x
ORDER BY ACPU DESC, AReads DESC

SELECT MIN(StartTime),MAX(StartTime) FROM tempdb..trc3

UPDATE tempdb..trc4
SET TextData = 
'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________            FROM @N N            LEFT JOIN A AS Expected ON N.I <> N.I          '
WHERE TextData LIKE 'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________%'

SELECT * FROM tempdb..trc2
WHERE TextData LIKE 'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________%'

DROP TABLE dbo.expected
SELECT 'DROP TABLE '+name+';' FROM sys.tables WHERE name LIKE 'tSQLt_tempobject%'


--*/

