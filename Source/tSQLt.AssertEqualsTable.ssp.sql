IF OBJECT_ID('tSQLt.AssertEqualsTable') IS NOT NULL DROP PROCEDURE tSQLt.AssertEqualsTable;
GO
---BUILD+
CREATE PROCEDURE tSQLt.AssertEqualsTable
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = NULL,
    @FailMsg NVARCHAR(MAX) = 'Unexpected/missing resultset rows!'
AS
BEGIN

    EXEC tSQLt.AssertObjectExists @Expected;
    EXEC tSQLt.AssertObjectExists @Actual;

    DECLARE @ResultTable NVARCHAR(MAX);    
    DECLARE @ResultTableWithSchema NVARCHAR(MAX);    
    DECLARE @ResultColumn NVARCHAR(MAX);    
    DECLARE @ColumnList NVARCHAR(MAX);    
    DECLARE @UnequalRowsExist INT;
    DECLARE @CombinedMessage NVARCHAR(MAX);

    SELECT @ResultTable = tSQLt.Private::CreateUniqueObjectName();
    SELECT @ResultColumn = 'RC_' + @ResultTable;
    SELECT @ResultTableWithSchema = 'tSQLt.' + @ResultTable; 

    EXEC tSQLt.Private_CreateResultTableForCompareTables 
      @ResultTable = @ResultTableWithSchema,
      @ResultColumn = @ResultColumn,
      @BaseTable = @Expected;
        
    SELECT @ColumnList = tSQLt.Private_GetCommaSeparatedColumnList(@ResultTableWithSchema, @ResultColumn);

    EXEC tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported @ResultTableWithSchema, @ColumnList;    
    
    EXEC @UnequalRowsExist = tSQLt.Private_CompareTables 
      @Expected = @Expected,
      @Actual = @Actual,
      @ResultTable = @ResultTableWithSchema,
      @ColumnList = @ColumnList,
      @MatchIndicatorColumnName = @ResultColumn;
        
    SET @CombinedMessage = ISNULL(@Message + CHAR(13) + CHAR(10),'') + @FailMsg;
    EXEC tSQLt.Private_CompareTablesFailIfUnequalRowsExists 
      @UnequalRowsExist = @UnequalRowsExist,
      @ResultTable = @ResultTableWithSchema,
      @ResultColumn = @ResultColumn,
      @ColumnList = @ColumnList,
      @FailMsg = @CombinedMessage;   
END;
---Build-
GO
