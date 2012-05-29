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
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= MinMax.Mn
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
    CROSS APPLY (SELECT MIN(x), MAX(x) 
                   FROM(
                     SELECT [_{Left}_] x 
                     UNION ALL 
                     SELECT [_{Right}_]
                     ) AS X
                 ) AS MinMax(Mn,Mx)
    CROSS APPLY (SELECT * FROM tSQLt.F_Num(MinMax.Mx)) AS RestoredRowIndex('+@RestoredRowIndexCounterColName+');';
    
    EXEC (@cmd);
    
    
    SET @cmd = 'SET @r = CASE WHEN EXISTS(SELECT 1 FROM ' + @ResultTable + ' WHERE ' + @MatchIndicatorColumnName + ' IN (''<'', ''>'')) THEN 1 ELSE 0 END';
    DECLARE @UnequalRowsExist INT;
    EXEC sp_executesql @cmd, N'@r INT OUTPUT',@UnequalRowsExist OUTPUT;
    
    RETURN @UnequalRowsExist;
END;
---Build-
