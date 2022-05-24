# FakeFunction

## Syntax

``` sql
tSQLt.FakeFunction [@FunctionName = ] 'function name'
                 , [@FakeFunctionName = ] 'fake function name'
```

## Arguments

[**@FunctionName** = ] ‘function name’

The name of an existing function. @FunctionName is NVARCHAR(MAX) with no default. @FunctionName should include the schema name of the function. For example: MySchema.MyFunction

[**@FakeFunctionName** = ] ‘fake function name’

The name of an existing function that will replace the function defined by @FunctionName during the test. @FakeFunctionName is NVARCHAR(MAX) with no default.

## Return code values
Returns 0

## Error raised

If the function itself or the fake function does not exist, the follow error is raised: ‘function name’ does not exist

If the function and the fake function are not compatible function types (i.e. they must both be scalar functions or both be table valued functions), the following error is raised: Both parameters must contain the name of either scalar or table valued functions!

If the parameters of the function and fake function are not the same, the following error is raised: Parameters of both functions must match! (This includes the return type for scalar functions.)

## Result sets
None

## Overview
Code that calls a function can be difficult to test if that function performs significant logic. We want to isolate the code we are testing from the logic buried in the functions that it calls. To create independent tests, we can replace a called function with a fake function. The fake function will perform much simpler logic that supports the purpose of our test. Often, the fake function will simply return a hard-coded value.

Alternatively, the fake function may ‘validate’ the parameters it receives by returning one value if the parameters match expectations, and another value if the parameters do not match expectations. That way the code that calls the function will have a different result and thus the parameter passed to the function can be tested.

## Warnings
Remember that if you are faking a function, you are not testing that function. Your test is trying to test something else: typically, the logic of a view, stored procedure or another function that interacts with the function you are faking.

## Examples
**Example: Using FakeFunction to avoid executing the logic of a complex function**

In this example, we want to test a sales report view, SalesReport. The sales report view will return the EmployeeId, RevenueFromSales (the total amount of new revenue the employee generated) and their Commission. (The commision has to be calculated with a complex algorithm using RevenueFromSales and values read from the EmployeeCompensation table. This computation is done by the ComputeCommision scalar function.)

Since we are testing the SalesReport view, we will fake the ComputeCommission function.

``` sql
EXEC tSQLt.NewTestClass 'SalesAppTests';
GO

CREATE FUNCTION SalesAppTests.Fake_ComputeCommission (
    @EmployeeId INT, 
    @RevenueFromSales DECIMAL(10,4)
)
RETURNS DECIMAL(10,4)
AS
BEGIN
  RETURN 1234.5678;
END;
GO

CREATE PROCEDURE SalesAppTests.[test SalesReport returns revenue and commission]
AS
BEGIN
-------Assemble
    EXEC tSQLt.FakeFunction 'SalesApp.ComputeCommission', 'SalesAppTests.Fake_ComputeCommission';
    EXEC tSQLt.FakeTable 'SalesApp.Employee';
    EXEC tSQLT.FakeTable 'SalesApp.Sales';

    INSERT INTO SalesApp.Employee (EmployeeId) VALUES (1);
    INSERT INTO SalesApp.Sales (EmployeeId, SaleAmount) VALUES (1, 10.1);
    INSERT INTO SalesApp.Sales (EmployeeId, SaleAmount) VALUES (1, 20.2);

-------Act
    SELECT EmployeeId, RevenueFromSales, Commission
      INTO SalesAppTests.Actual
      FROM SalesApp.SalesReport;

-------Assert
    SELECT TOP(0) *
      INTO SalesAppTests.Expected
      FROM SalesAppTests.Actual;

    INSERT INTO SalesAppTests.Expected (EmployeeId, RevenueFromSales, Commission) 
      VALUES (1, 30.3, 1234.5678);

    EXEC tSQLt.AssertEqualsTable 'SalesAppTests.Expected', 'SalesAppTests.Actual';
END;
GO
```