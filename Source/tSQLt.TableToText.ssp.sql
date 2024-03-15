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
    -- SET @txt = tSQLt.Private::TableToString(@TableName, @OrderBy, @PrintOnlyColumnNameAliasList);
    -- SELECT TOP(0) C.column_id,C.name INTO [#tSQLt.TableToText.Columns] FROM sys.columns C;
    SELECT * INTO [#tSQLt.TableToText.Tmp] FROM #DoesExist;
    DECLARE @tmpObjectId INT = OBJECT_ID('tempdb..[#tSQLt.TableToText.Tmp]');
    -- INSERT INTO [#tSQLt.TableToText.Columns]
    -- SELECT ROW_NUMBER()OVER(ORDER BY C.column_id),name FROM sys.columns C WHERE C.object_id = OBJECT_ID('tempdb..[#tSQLt.TableToText.Tmp]');
    SELECT name+'|' FROM sys.columns WHERE object_id = @tmpObjectId;

END;
GO
---Build-
