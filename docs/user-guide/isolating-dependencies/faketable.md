# FakeTable

## Syntax

```sql
tSQLt.FakeTable [@TableName = ] 'table name'
                , [[@SchemaName = ] 'schema name']
                , [[@Identity = ] 'preserve identity']
                , [[@ComputedColumns = ] 'preserve computed columns']
                , [[@Defaults = ] 'preserve default constraints']
```

## Arguments

[**@TableName =** ] ‘table name’

The name of the table for which to create a fake table. Should contain both the schema name and the table name.

[**@SchemaName =** ] ‘schema name’ – **Deprecated: do not use, will be removed in future version**

[**@Identity =** ] ‘preserve identity’ – Indicates if the identity properties of an identity column should be preserved. If @Identity = 1, the identity properties will be preserved, otherwise the faked table will have the identity properties removed. The default is @Identity = 0.

[**@ComputedColumns =** ] ‘preserve computed columns’ – Indicates if the computations on computed columns should be preserved. If @ComputedColumns = 1, the computations will be preserved, otherwise the faked table will have computations removed from computed columns. The default is @ComputedColumns = 0.

[**@Defaults =** ] ‘preserve default constraints’ – Indicates if the default constraints on columns should be preserved. If @Defaults = 1, default constraints will be preserved for all columns on the faked table, otherwise the faked table will not contain default constraints. The default is @Defaults = 0.

## Return Code Values

Returns 0

## Error Raised

If the specified table does not exist an error is thrown: FakeTable could not resolve the object name, ‘%s’.

## Result Sets

None

## Overview

We want to keep our test cases focused and do not want to insert data which is irrelevant to the current test. However, table and column constraints can make this difficult.

FakeTable allows tests to be written in isolation of the constraints on a table. FakeTable creates an empty version of the table without the constraints in place of the specified table. Therefore any statements which access the table during the execution of the test case are actually working against the fake table with no constraints. When the test case completes, the original table is put back in place because of the rollback which tSQLt performs at the end of each test case.

FakeTable can be called on Tables, Views and Synonyms (A Synonym has to point to a table or view in the current database.)

## Limitations

FakeTable cannot be used with temporary tables (tables whose names begin with # or ##).

## Warnings

Remember if you are faking a table, you are not testing the constraints on the table. You will want test cases that also exercise the constraints on the table. See Also: ApplyConstraint.

## Examples

**Example: Faking a table to create test data to test a view**

In this example, we have a FinancialApp.ConvertCurrencyUsingLookup view which accesses the FinancialApp.CurrencyConversion table. In order to test the view, we want to freely insert data into the table. FakeTable is used to remove the constraints from the CurrencyConversion table so that the data record can be inserted.

```sql
CREATE PROCEDURE testFinancialApp.[test that ConvertCurrencyUsingLookup converts using conversion rate in CurrencyConversion table]
AS
BEGIN
    DECLARE @expected MONEY; SET @expected = 3.2;
    DECLARE @actual MONEY;
    DECLARE @amount MONEY; SET @amount = 2.00;
    DECLARE @sourceCurrency CHAR(3); SET @sourceCurrency = 'EUR';
    DECLARE @destCurrency CHAR(3); SET @destCurrency = 'USD';

------Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp.CurrencyConversion';

    INSERT INTO FinancialApp.CurrencyConversion (id, SourceCurrency, DestCurrency, ConversionRate)
                                         VALUES (1, @sourceCurrency, @destCurrency, 1.6);
------Execution
    SELECT @actual = amount FROM FinancialApp.ConvertCurrencyUsingLookup(@sourceCurrency, @destCurrency, @amount);

------Assertion
    EXEC tSQLt.assertEquals @expected, @actual;
END;
GO
```

**Example: Calling FakeTable with @Identity = 1**

We need to specify the @Identity parameter explicitly because the second parameter (@SchemaName) has been deprecated. This same pattern applies to @ComputedColumns and @Defaults.

```sql
EXEC tSQLt.FakeTable 'FinancialApp.CurrencyConversion', @Identity = 1;
```