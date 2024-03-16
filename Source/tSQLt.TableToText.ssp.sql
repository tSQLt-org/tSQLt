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
    DECLARE @cmd NVARCHAR(MAX)=
    'SELECT * INTO [#tSQLt.TableToText.Tmp] FROM '+@TableName+';'+
    'DECLARE @tmpObjectId INT = OBJECT_ID(''tempdb..[#tSQLt.TableToText.Tmp]'');'+
    'DECLARE @cmd NVARCHAR(MAX) = (SELECT '',CAST(''+QUOTENAME(name,'''''''')+'' AS NVARCHAR(MAX)) C''+RIGHT(CAST(10002+ROW_NUMBER()OVER(ORDER BY column_id) AS NVARCHAR(MAX)),4) FROM tempdb.sys.columns WHERE object_id = @tmpObjectId ORDER BY column_id FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)'');'+
    'SET @txt = ''SELECT 1''+@cmd+'' INTO [#tSQLt.TableToText.Str];'';';

    EXEC sys.sp_executesql @cmd,N'@txt NVARCHAR(MAX) OUT',@txt OUT;
END;
GO
---Build-
