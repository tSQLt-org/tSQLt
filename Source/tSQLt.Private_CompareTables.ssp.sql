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
    INSERT INTO ' + @ResultTable + ' (' + @MatchIndicatorColumnName + ', ' + @ColumnList + ') 
    SELECT 
      CASE 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= CASE WHEN [_{Left}_]<[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END
         THEN ''='' 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= [_{Left}_] 
         THEN ''<'' 
        ELSE ''>'' 
      END AS ' + @MatchIndicatorColumnName + ', ' + @ColumnList + '
    FROM(
      SELECT SUM([_{Left}_]) AS [_{Left}_], 
             SUM([_{Right}_]) AS [_{Right}_], 
             ' + @ColumnList + ' 
      FROM (
        SELECT 1 AS [_{Left}_], 0[_{Right}_], ' + @ColumnList + '
          FROM ' + @Expected + '
        UNION ALL 
        SELECT 0[_{Left}_], 1 AS [_{Right}_], ' + @ColumnList + ' 
          FROM ' + @Actual + '
      ) AS X 
      GROUP BY ' + @ColumnList + ' 
    ) AS CollapsedRows
    CROSS APPLY (
       SELECT TOP(CASE WHEN [_{Left}_]>[_{Right}_] THEN [_{Left}_] 
                       ELSE [_{Right}_] END) 
              ROW_NUMBER() OVER(ORDER BY(SELECT 1)) 
         FROM (SELECT 1 
                 FROM ' + @Actual + ' UNION ALL SELECT 1 FROM ' + @Expected + ') X(X)
              ) AS RestoredRowIndex(' + @RestoredRowIndexCounterColName + ');';
--TODO:                                                                                                         need to create enough rows here --^
--  Testcases:
--    all data types, including different CLRs
--
--  Change [_{xxx}_] into [_{xxx}_' + @ResultTable + ']
--Should @ResultTable contain the schema name?
--
--Performance Testing Material at the end of this file
--
--Old version:
--    CROSS APPLY (SELECT * FROM tSQLt.F_Num(CASE WHEN [_{Left}_]>[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END)) AS RestoredRowIndex('+@RestoredRowIndexCounterColName+');';
    
    EXEC (@cmd);--MainGroupQuery
    
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

--*/



/* ---Spatial Data


IF OBJECT_ID('ttttt') IS NOT NULL DROP TABLE dbo.ttttt;

CREATE TABLE ttttt(i INT, g1 geometry, g2 geography)

INSERT INTO ttttt VALUES(1,geometry::STGeomFromText('MULTILINESTRING((0 2, 1 1), (1 0, 1 1))', 0),geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326));

INSERT INTO ttttt VALUES(1,geometry::STGeomFromText('MULTILINESTRING((1 0, 1 1), (0 2, 1 1))', 0),geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326));


SELECT 
--COUNT(1),
i,g1.AsTextZM(),g2.AsTextZM(),g1.ToString(),g2.ToString(),g1.AsGml(),g2.AsGml(),g1.AsGml(),g2.AsGml()
FROM dbo.ttttt
--GROUP BY i,g1.AsTextZM(),g1.AsGml(),g2.AsTextZM(),g2.AsGml()

SELECT geometry::STGeomFromText('MULTILINESTRING((0 2, 1 1), (1 0, 1 1))', 0).STEquals(geometry::STGeomFromText('MULTILINESTRING((1 0, 1 1), (0 2, 1 1))', 0))


For XML check out:
http://web.archive.org/web/20090629063725/http://www.pluralsight.com/community/blogs/dan/archive/2006/09/01/36829.aspx
http://web.archive.org/web/20081026094705/http://www.sqlserverandxml.com/2008/09/xquery-lab-36-writing-tsql-function-to.html
--*/