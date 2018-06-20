IF OBJECT_ID('tSQLt.Private_CompareTables') IS NOT NULL DROP PROCEDURE tSQLt.Private_CompareTables;
GO
---Build+
GO
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
    
    EXEC (@cmd); --MainGroupQuery
    
    SET @cmd = 'SET @r = 
         CASE WHEN EXISTS(
                  SELECT 1 
                    FROM ' + @ResultTable + 
                 ' WHERE ' + @MatchIndicatorColumnName + ' IN (''<'', ''>'')) 
              THEN 1 ELSE 0 
         END';
    DECLARE @UnequalRowsExist INT;
    EXEC sp_executesql @cmd, N'@r INT OUTPUT',@UnequalRowsExist OUTPUT;

    -- TODO find better solution!
    SET @cmd = N'DECLARE @Overflow bigint = ( SELECT COUNT_BIG(*)
                                 FROM   ' + @ResultTable + N' ) - 20;
    IF @Overflow > 0
    BEGIN;
        WITH cte
          AS ( SELECT   TOP ( @Overflow )
                        *
               FROM     ' + @ResultTable + N'
               ORDER BY CASE WHEN ' + @MatchIndicatorColumnName + N' IN (''<'', ''>'')
                                 THEN 1
                             ELSE 0
                        END )
        DELETE cte;

        INSERT INTO ' + @ResultTable + N'
            ( ' + @MatchIndicatorColumnName + N' )
        VALUES ( ''?'' );
    END;';
    EXEC sys.sp_executesql @cmd;
    
    RETURN @UnequalRowsExist;
END;
---Build-
GO
