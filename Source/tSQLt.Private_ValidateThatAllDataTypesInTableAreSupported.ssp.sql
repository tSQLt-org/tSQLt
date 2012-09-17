IF OBJECT_ID('tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported;
GO
---BUILD+
CREATE PROCEDURE tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported
 @ResultTable NVARCHAR(MAX),
 @ColumnList NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
      EXEC('DECLARE @EatResult INT; SELECT @EatResult = COUNT(1) FROM ' + @ResultTable + ' GROUP BY ' + @ColumnList + ';');
    END TRY
    BEGIN CATCH
      RAISERROR('The table contains a datatype that is not supported for tSQLt.AssertEqualsTable. Please refer to http://tsqlt.org/user-guide/assertions/assertequalstable/ for a list of unsupported datatypes.',16,10);
    END CATCH
END;
---BUILD-
GO
