# AssertEquals

## Syntax

``` sql
tSQLt.AssertEquals [@expected = ] expected value, [@actual = ] actual value[, [@message = ] 'message' ]
```

## Arguments
[**@Expected** = ] expected value

The expected value for the test. @Expected is SQL_VARIANT with no default.

[**@Actual** = ] actual value

The actual value resulting from processing during the test. @Actual is SQL_VARIANT with no default.

[**@Message** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @Message is NVARCHAR(MAX) with no default.

## Return Code Values
Returns 0

## Error Raised
Raises a `failure` error if expected and actual are not equal.

Raises an `Operand type clash` error if the value passed for @Expected or @Actual is not compatible with SQL_VARIANT. The most common form of this is VARCHAR(MAX) – for this `tSQLt.AssertEqualsString` is provided.

## Result Sets
None

## Overview
`tSQLt.AssertEquals` compares two values for equality. If they are not equal, the test case is failed; otherwise, `tSQLt.AssertEquals` does not affect test processing. For the purposes of `tSQLt.AssertEquals`, NULL is considered equal to NULL. Any non-NULL value is considered not equal to NULL.

## Examples
### Example: `tSQLt.AssertEquals` to check the results of a function
This test case uses `tSQLt.AssertEquals` to compare the return result of a function with an expected value.

``` sql
CREATE PROCEDURE testFinancialApp.[test that ConvertCurrencyUsingLookup converts using conversion rate in CurrencyConversion table]
AS
BEGIN
    DECLARE @expected MONEY; SET @expected = 3.2;
    DECLARE @actual MONEY;
    DECLARE @amount MONEY; SET @amount = 2.00;
    DECLARE @sourceCurrency CHAR(3); SET @sourceCurrency = 'EUR';
    DECLARE @destCurrency CHAR(3); SET @destCurrency = 'USD';

------Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp', 'CurrencyConversion';

    INSERT INTO FinancialApp.CurrencyConversion (id, SourceCurrency, DestCurrency, ConversionRate)
                                         VALUES (1, @sourceCurrency, @destCurrency, 1.6);
------Execution
    SELECT @actual = amount FROM FinancialApp.ConvertCurrencyUsingLookup(@sourceCurrency, @destCurrency, @amount);

------Assertion
    EXEC tSQLt.assertEquals @expected, @actual;
END;
GO
```

### Example: A variety of the possibilities of `tSQLt.AssertEquals`

The examples below show what to expect from AssertEquals when called with different values.

``` sql
    EXEC tSQLt.AssertEquals 12345.6789, 12345.6789; -- pass
    EXEC tSQLt.AssertEquals 'hello', 'hello'; -- pass
    EXEC tSQLt.AssertEquals N'hello', N'hello'; -- pass

    DECLARE @datetime DATETIME; SET @datetime = CAST('12-13-2005' AS DATETIME);
    EXEC tSQLt.AssertEquals @datetime, @datetime; -- pass

    DECLARE @bit BIT; SET @bit = CAST(1 AS BIT);
    EXEC tSQLt.AssertEquals @bit, @bit; -- pass

    EXEC tSQLt.AssertEquals NULL, NULL; -- pass
    EXEC tSQLt.AssertEquals 17, NULL; -- fail
    EXEC tSQLt.AssertEquals NULL, 17; -- fail

    EXEC tSQLt.AssertEquals 12345.6789, 54321.123; -- fail
    EXEC tSQLt.AssertEquals 'hello', 'goodbye'; -- fail

    DECLARE @datetime1 DATETIME; SET @datetime1 = CAST('12-13-2005' AS DATETIME);
    DECLARE @datetime2 DATETIME; SET @datetime2 = CAST('07-19-2005' AS DATETIME);
    EXEC tSQLt.AssertEquals @datetime1, @datetime2; -- fail

    DECLARE @bit1 BIT; SET @bit1 = CAST(1 AS BIT);
    DECLARE @bit2 BIT; SET @bit2 = CAST(1 AS BIT);
    EXEC tSQLt.AssertEquals @bit1, @bit2; -- pass
```