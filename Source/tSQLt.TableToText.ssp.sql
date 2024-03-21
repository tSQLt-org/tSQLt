IF OBJECT_ID('tSQLt.TableToText') IS NOT NULL DROP PROCEDURE tSQLt.TableToText;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.TableToText
    @txt NVARCHAR(MAX) OUTPUT,
    @TableName NVARCHAR(MAX),
    @OrderBy NVARCHAR(MAX) = NULL,
    @PrintOnlyColumnNameAliasList NVARCHAR(MAX) = NULL
AS
BEGIN
    IF(@TableName IS NULL)
    BEGIN
      RAISERROR('@TableName cannot be NULL',16,10)
    END;
    DECLARE @TmpTableName NVARCHAR(MAX) = 'tSQLt.[TableToText.Tmp.'+CAST(NEWID() AS NVARCHAR(MAX))+']';
    PRINT @TmpTableName
    IF(OBJECT_ID(@TmpTableName)IS NOT NULL) EXEC('DROP TABLE '+@TmpTableName);
    IF(OBJECT_ID('tempdb..[#tSQLt.TableToText.Str]')IS NOT NULL) DROP TABLE [#tSQLt.TableToText.Str];
    IF(OBJECT_ID('tempdb..[#tSQLt.TableToText.Str.Len]')IS NOT NULL) DROP TABLE [#tSQLt.TableToText.Str.Len];
    DECLARE @nl NVARCHAR(MAX) = 'CHAR(13)+CHAR(10)'
    DECLARE @MaxColumnWidth INT = 155;
    DECLARE @cmd NVARCHAR(MAX)=
    'SET NOCOUNT ON;'+
    'SELECT * INTO '+@TmpTableName+' FROM (SELECT ROW_NUMBER()OVER(ORDER BY '+
            CASE WHEN NULLIF(LTRIM(@OrderBy),'') IS NULL
              THEN '(SELECT 1)'
              ELSE @OrderBy
            END+')+2 [tSQLt.TableToText.OrderBy],* FROM '+@TableName+')X'+
            --
            CASE WHEN NULLIF(LTRIM(@PrintOnlyColumnNameAliasList),'') IS NULL
              THEN ''
              ELSE '([tSQLt.TableToText.OrderBy],'+@PrintOnlyColumnNameAliasList+')'
            END+';'+
    'DECLARE @tmpObjectId INT = OBJECT_ID('''+@TmpTableName+''');'+
    'DECLARE @column_list NVARCHAR(MAX) = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListQuotedAndNumbered(@tmpObjectId));'+
    'DECLARE @cmd NVARCHAR(MAX)=''SELECT 1 no,''''|'''' sep''+@column_list+'' INTO [#tSQLt.TableToText.Str];'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumntoStringList(@tmpObjectId));'+
    'SET @cmd = @cmd + ''INSERT INTO [#tSQLt.TableToText.Str] SELECT [tSQLt.TableToText.OrderBy],''''|''''''+@column_list+'' FROM [#tSQLt.TableToText.Tmp];'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListMaxLenNumbered(@tmpObjectId));'+
    'SET @cmd = @cmd + ''SELECT '+STR(@MaxColumnWidth)+' MCW''+@column_list+'' INTO [#tSQLt.TableToText.Str.Len] FROM [#tSQLt.TableToText.Str];'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListAdjustWidth(@tmpObjectId));'+
    'SET @cmd = @cmd + ''WITH LenAdjusted AS ('';'+
    'SET @cmd = @cmd + ''SELECT no,sep''+@column_list+'' FROM [#tSQLt.TableToText.Str.Len] L CROSS JOIN [#tSQLt.TableToText.Str] C'';'+
    'SET @cmd = @cmd + '' UNION ALL '';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListSeparatorLine(@tmpObjectId));'+
    'SET @cmd = @cmd + ''SELECT 2,''''+'''' ''+@column_list+'' FROM [#tSQLt.TableToText.Str.Len] L'';'+
    'SET @cmd = @cmd + '')'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextNumberedColumnsWithSeparator(@tmpObjectId));'+
    'SET @cmd = @cmd+''SELECT @txt=STUFF((SELECT '+@nl+'+''+@column_list+''sep FROM LenAdjusted ORDER BY no FOR XML PATH(''''''''),TYPE).value(''''.'''',''''NVARCHAR(MAX)''''),1,2,'''''''');'';'+
    -- 'PRINT @cmd;'+
    'EXEC sys.sp_executesql @cmd,N''@txt NVARCHAR(MAX) OUT'',@txt OUT;';
    -- PRINT @cmd;
    EXEC sys.sp_executesql @cmd,N'@txt NVARCHAR(MAX) OUT',@txt OUT;
END;
GO
---Build-
