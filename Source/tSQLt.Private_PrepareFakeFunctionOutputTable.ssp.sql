IF OBJECT_ID('tSQLt.Private_PrepareFakeFunctionOutputTable') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_PrepareFakeFunctionOutputTable
    @FakeDataSource NVARCHAR(MAX) ,
    @OutputTable    sysname OUTPUT
AS
    BEGIN
        SET @OutputTable = 'tmp' + REPLACE(CAST(NEWID() AS CHAR(36)), '-','');

        IF ( LOWER(LTRIM(@FakeDataSource)) LIKE 'select%'
             AND OBJECT_ID(@FakeDataSource) IS NULL
           )
            BEGIN
                SET @FakeDataSource = N'(' + @FakeDataSource + N') a';
            END;

        DECLARE @newTblStmt VARCHAR(2000) = 'SELECT * INTO ' + @OutputTable
            + ' FROM ' + @FakeDataSource;

        EXEC tSQLt.SuppressOutput @command = @newTblStmt;

        RETURN 0;
    END;
---Build-
GO