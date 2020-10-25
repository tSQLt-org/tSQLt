IF OBJECT_ID('tSQLt.Private_PrepareFakeFunctionOutputTable') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable
    @FakeDataSource NVARCHAR(MAX),
    @OutputTable    NVARCHAR(MAX) OUTPUT
AS
    BEGIN
        SET @OutputTable = tSQLt.Private::CreateUniqueObjectName();

        IF ( LOWER(LTRIM(@FakeDataSource)) LIKE 'select%'
             AND OBJECT_ID(@FakeDataSource) IS NULL
           )
            BEGIN
                SET @FakeDataSource = CONCAT(N'(', @FakeDataSource, N') a');
            END;

        DECLARE @Cmd NVARCHAR(MAX) = CONCAT('SELECT * INTO ', @OutputTable, ' FROM ', @FakeDataSource);

        EXEC sp_executesql @Cmd;

        RETURN 0;
    END;
---Build-
GO
