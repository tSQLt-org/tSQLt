# AssertEqualsTable

## Syntax

``` sql
tSQLt.AssertEqualsTable [@Expected = ] 'expected table name'
                      , [@Actual = ] 'actual table name'
                     [, [@FailMsg = ] 'message' ]
```

## Arguments
[**@Expected** = ] expected table name

The name of a table which contains the expected results for the test. @Expected is NVARCHAR(MAX) with no default.

[**@Actual** = ] actual table name

The name of a table which contains the results from processing during the test. @Actual is NVARCHAR(MAX) with no default.

[**@FailMsg** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @FailMsg is NVARCHAR(MAX) with a default of ‘unexpected/missing resultset rows!’.

## Return Code Values
Returns 0

## Errors Raised
Raises a `failure` error if the contents of the expected table and the actual table are not equal.

Certain datatypes cannot be compared with `tSQLt.AssertEqualsTable`. If the tables being compared contain an unsupported datatype, the following error will be raised:

 > The table contains a datatype that is not supported for `tSQLt.AssertEqualsTable`.

The following datatypes are known to be unsupported by `tSQLt.AssertEqualsTable`: text, ntext, image, xml, geography, geometry, rowversion and CLR datatypes that are not marked comparable and byte ordered.

## Result Sets
None

## Overvoew
`tSQLt.AssertEqualsTable` compares the contents of two tables for equality. It does this by comparing each row of the tables for an exact match on all columns. If the tables do not contain the same data, the failure message displays which rows could not be matched.

## Examples
### Example: AssertEqualsTable to check the results of a view
This test case uses AssertEqualsTable to compare the data returned by a view to an expected data set.

``` sql
CREATE PROCEDURE testFinancialApp.[test that Report gets sales data with converted currency]
AS
BEGIN
    IF OBJECT_ID('actual') IS NOT NULL DROP TABLE actual;
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp', 'CurrencyConversion';
    EXEC tSQLt.FakeTable 'FinancialApp', 'Sales';

    INSERT INTO FinancialApp.CurrencyConversion (id, SourceCurrency, DestCurrency, ConversionRate)
                                         VALUES (1, 'EUR', 'USD', 1.6);
    INSERT INTO FinancialApp.CurrencyConversion (id, SourceCurrency, DestCurrency, ConversionRate)
                                         VALUES (2, 'GBP', 'USD', 1.2);

    INSERT INTO FinancialApp.Sales (id, amount, currency, customerId, employeeId, itemId, date)
                                         VALUES (1, '1050.00', 'GBP', 1000, 7, 34, '1/1/2007');
    INSERT INTO FinancialApp.Sales (id, amount, currency, customerId, employeeId, itemId, date)
                                         VALUES (2, '4500.00', 'EUR', 2000, 19, 24, '1/1/2008');

------Execution
    SELECT amount, currency, customerId, employeeId, itemId, date
      INTO actual
      FROM FinancialApp.Report('USD');

------Assertion
    CREATE TABLE expected (
	    amount MONEY,
	    currency CHAR(3),
	    customerId INT,
	    employeeId INT,
	    itemId INT,
	    date DATETIME
    );

	INSERT INTO expected (amount, currency, customerId, employeeId, itemId, date) SELECT 1260.00, 'USD', 1000, 7, 34, '2007-01-01';
	INSERT INTO expected (amount, currency, customerId, employeeId, itemId, date) SELECT 7200.00, 'USD', 2000, 19, 24, '2008-01-01';

	EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO
```

## Understanding The Output
When the two tables being compared contain different data, the results are displayed as a text table in the failure message. The first column of this text table (\_m\_) describes the result of the comparison. The symbol “<” indicates that the row was found in the Expected table but did not match anything in the Actual table. The symbol “>” indicates that the row was found in the Actual table but not in the Expected table. Finally, the symbol “=” indicates that the row was matched between the Expected and Actual tables.

For example, consider the following Expected and Actual tables:

Expected
|col1|col2|col3|
|---|---|---|
|1|A|a|
|2|B|b|
|3|C|c|

Actual
|col1|col2|col3|
|---|---|---|
|1|A|a|
|3|X|c|

These tables would result in the following failure message:


`failed: unexpected/missing resultset rows!`
|_m_|col1|col2|col3|
|---|---|---|---|
|<  |2   |B   |b   |
|<  |3   |C   |c   |
|=  |1   |A   |a   |
|>  |3   |X   |c   |
