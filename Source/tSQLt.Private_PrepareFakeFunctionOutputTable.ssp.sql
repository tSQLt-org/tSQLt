IF OBJECT_ID('tSQLt.Private_PrepareFakeFunctionOutputTable') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable
    @FakeDataSource NVARCHAR(MAX),
    @FunctionName    NVARCHAR(MAX),
    @OutputTable    sysname OUTPUT
AS
    BEGIN
        DECLARE @SchemaName SYSNAME;
        SET @SchemaName = COALESCE(PARSENAME(@FunctionName, 2), 'tSQlt');
        SET @FunctionName = LEFT(PARSENAME(@FunctionName, 1), 100);
        SET @OutputTable = CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(CONCAT(@FunctionName, '_', 'FakeFunctionOutputTable')));

        IF ( LOWER(LTRIM(@FakeDataSource)) LIKE 'select%'
             AND OBJECT_ID(@FakeDataSource) IS NULL
           )
            BEGIN
                SET @FakeDataSource = N'(' + @FakeDataSource + N') a';
            END;

        DECLARE @Cmd NVARCHAR(2000) = CONCAT('SELECT * INTO ', @OutputTable, ' FROM ', @FakeDataSource);

        EXEC sp_executesql @Cmd;

        RETURN 0;
    END;
---Build-
GO
