# AssertEmptyTable

## Syntax

``` sql
tSQLt.AssertEmptyTable [@TableName = ] 'name of table to be checked' [, [@Message = ] 'message' ]
```

## Arguments

[**@TableName** = ] name of table to be checked

The name of a table which is expected to be empty. @TableName is NVARCHAR(MAX) with no default.

[**@Message** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @Message is NVARCHAR(MAX) with a default of ‘unexpected/missing resultset rows!’.

## Return Code Values

Returns 0

## Errors Raised

Raises a `failure` error if the table contains any rows.

## Result Sets
None

## Overview

AssertEmptyTable succeeds when a table is empty, fails otherwise. The failure message displays all rows that are found.

## Examples

This example uses AssertEmptyTable to check that a table-valued function returns an empty resultset.

``` sql
CREATE PROCEDURE testFinancialApp.[test that Report generates no rows if base tables are empty]
AS
BEGIN
    IF OBJECT_ID('actual') IS NOT NULL DROP TABLE actual;

------Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp', 'CurrencyConversion';
    EXEC tSQLt.FakeTable 'FinancialApp', 'Sales';

------Execution
    SELECT amount, currency, customerId, employeeId, itemId, date
      INTO actual
      FROM FinancialApp.Report('USD');

------Assertion
    EXEC tSQLt.AssertEmptyTable 'actual';
END;
GO
```
