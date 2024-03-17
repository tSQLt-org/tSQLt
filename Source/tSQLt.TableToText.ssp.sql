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
    DECLARE @nl NVARCHAR(MAX) = 'CHAR(13)+CHAR(10)'
    DECLARE @MaxColumnWidth INT = 155;
    DECLARE @cmd NVARCHAR(MAX)=
    'SELECT * INTO [#tSQLt.TableToText.Tmp] FROM '+@TableName+';'+
    'DECLARE @tmpObjectId INT = OBJECT_ID(''tempdb..[#tSQLt.TableToText.Tmp]'');'+
    'DECLARE @column_list NVARCHAR(MAX) = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListQuotedAndNumbered(@tmpObjectId));'+
    'DECLARE @cmd NVARCHAR(MAX)=''SELECT 1 no,''''|'''' sep''+@column_list+'' INTO [#tSQLt.TableToText.Str];'';'+
    'SET @column_list = '',*'';'+
    'SET @cmd = @cmd + ''INSERT INTO [#tSQLt.TableToText.Str] SELECT ROW_NUMBER()OVER(ORDER BY (SELECT 1))+2,''''|''''''+@column_list+'' FROM [#tSQLt.TableToText.Tmp];'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListMaxLenNumbered(@tmpObjectId));'+
    'SET @cmd = @cmd + ''SELECT '+STR(@MaxColumnWidth)+' MCW''+@column_list+'' INTO [#tSQLt.TableToText.Str.Len] FROM [#tSQLt.TableToText.Str];'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListAdjustWidth(@tmpObjectId));'+
    'SET @cmd = @cmd + ''WITH LenAdjusted AS ('';'+
    'SET @cmd = @cmd + ''SELECT no,sep''+@column_list+'' FROM [#tSQLt.TableToText.Str.Len] L CROSS JOIN [#tSQLt.TableToText.Str] C'';'+
    'SET @cmd = @cmd + '' UNION ALL '';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextColumnListSeparatorLine(@tmpObjectId));'+
    'SET @cmd = @cmd + ''SELECT 2,''''+'''',''+@column_list+'' FROM [#tSQLt.TableToText.Str.Len]'';'+
    'SET @cmd = @cmd + '')'';'+
    'SET @column_list = (SELECT ColumnList FROM tSQLt.Private_TableToTextNumberedColumnsWithSeparator(@tmpObjectId));'+
    'SET @cmd = @cmd+''SELECT @txt=STUFF((SELECT '+@nl+'+''+@column_list+''sep FROM LenAdjusted ORDER BY no FOR XML PATH(''''''''),TYPE).value(''''.'''',''''NVARCHAR(MAX)''''),1,2,'''''''');'';'+
    'EXEC sys.sp_executesql @cmd,N''@txt NVARCHAR(MAX) OUT'',@txt OUT;';

    EXEC sys.sp_executesql @cmd,N'@txt NVARCHAR(MAX) OUT',@txt OUT;
END;
GO
---Build-
