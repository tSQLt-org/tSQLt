# AssertEmptyTable

## Syntax

`tSQLt.AssertEmptyTable [@TableName = ] 'name of table to be checked' [, [@Message = ] 'message' ]`

## Arguments

[@TableName = ] name of table to be checked
The name of a table which is expected to be empty. @Expected is NVARCHAR(MAX) with no default.
[@Message = ] ‘message’
Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @Message is NVARCHAR(MAX) with a default of ‘unexpected/missing resultset rows!’.

## Return Code Values

Returns 0

## Errors Raised

Raises a ‘failure’ error if the table contains any rows.

## Result Sets
None

## Overview

AssertEmptyTable checks if a table is empty. If the table does contain any rows, the failure message displays all rows found.

## Examples

Example: AssertEqualsTable to check the results of a view
This test case uses AssertEqualsTable to compare the data returned by a view to an expected data set.

```
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