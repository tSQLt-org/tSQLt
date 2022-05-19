# tSQLt Tutorial
Welcome to tSQLt, a unit testing framework for the T-SQL language for Microsoft SQL Server 2005 and beyond. tSQLt takes database unit testing a step further by providing methods to help isolate functionality to be tested. Before diving in to the isolation features, however, let’s start with a simple example.

## Example 1: AssertEquals
Suppose we are writing a function which calculates the result of a currency exchange. Our function will take two parameters, the amount to be exchanged and the exchange rate. Our test is as follows:

````SQL
EXEC tSQLt.NewTestClass 'testFinancialApp';
GO

CREATE PROCEDURE testFinancialApp.[test that ConvertCurrency converts using given conversion rate]
AS
BEGIN
    DECLARE @actual MONEY;
    DECLARE @rate DECIMAL(10,4); SET @rate = 1.2;
    DECLARE @amount MONEY; SET @amount = 2.00;

    SELECT @actual = FinancialApp.ConvertCurrency(@rate, @amount);

    DECLARE @expected MONEY; SET @expected = 2.4;   --(rate * amount)
    EXEC tSQLt.AssertEquals @expected, @actual;

END;
GO
````

Note, that we first use tSQLt.NewTestClass to create a new schema for our test cases. This allows us to organize our tests and execute them as a group, which we will call a test class. A test class can be executed as follows:

````SQL
EXEC tSQLt.Run 'testFinancialApp';
````

Our test procedure calls the ConvertCurrency procedure (in the FinancialApp schema), passing the exchange rate and amount. The return value is retrieved and compared against the expected value in the tSQLt.AssertEquals method.

## Example 2: FakeTable

Suppose we want to test a procedure that reads data from a table. We need to put data in this table to properly do the test. However, the table might have constraints such as checks and foreign keys that would make it difficult to put data in the table just for a test case. Instead of creating a lot of unnecessary data, we can replace the table by calling fakeTable. This will recreate the original table without constraints.

So suppose we want to test a more advanced currency conversion method that looks up the exchange rate from a CurrencyConversion table:

````SQL
CREATE PROCEDURE testFinancialApp.[test that ConvertCurrencyUsingLookup converts using conversion rate in CurrencyConversion table]
AS
BEGIN
    DECLARE @expected MONEY; SET @expected = 3.2;
    DECLARE @actual MONEY;
    DECLARE @amount MONEY; SET @amount = 2.00;
    DECLARE @sourceCurrency CHAR(3); SET @sourceCurrency = 'EUR';
    DECLARE @destCurrency CHAR(3); SET @destCurrency = 'USD';

    --Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp', 'CurrencyConversion';

    INSERT INTO FinancialApp.CurrencyConversion 
    (
        id
        , SourceCurrency
        , DestCurrency
        , ConversionRate
    )
    VALUES (1, @sourceCurrency, @destCurrency, 1.6);
    
    --Execution
    SELECT @actual = amount 
    FROM FinancialApp.ConvertCurrencyUsingLookup(@sourceCurrency, @destCurrency, @amount);

    --Assertion
    EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO
````

FakeTable takes two parameters, the schema and the table name to be faked. Because every test in tSQLt operates inside of a transaction, the original table is put back in place after the test finishes. FakeTable has allowed us to isolate the testing of the procedure independently of the rest of the database’s constraints.

## Example 3: AssertEqualsTable

To simplify the comparison of tables and resultsets, tSQLt introduces a table comparison feature: tSQLt.AssertEqualsTable.

In this example, we want to generate a sales report. Our sales table tracks the amount of sale in the original currency, but since we want consistent data we should use our currency converter to make sure the report shows everything in a single currency.

````SQL
CREATE PROCEDURE testFinancialApp.[test that Report gets sales data with converted currency]
AS
BEGIN
    IF OBJECT_ID('actual') IS NOT NULL DROP TABLE actual;
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

    --Fake Table
    EXEC tSQLt.FakeTable 'FinancialApp', 'CurrencyConversion';
    EXEC tSQLt.FakeTable 'FinancialApp', 'Sales';

    INSERT INTO FinancialApp.CurrencyConversion 
    (
        id
        , SourceCurrency
        , DestCurrency
        , ConversionRate
    )
    VALUES (1, 'EUR', 'USD', 1.6);
    
    INSERT INTO FinancialApp.CurrencyConversion 
    (
        id
        , SourceCurrency
        , DestCurrency
        , ConversionRate
    )
    VALUES (2, 'GBP', 'USD', 1.2);

    INSERT INTO FinancialApp.Sales 
    (
        id
        , amount
        , currency
        , customerId
        , employeeId
        , itemId
        , date
    )
    VALUES (1, '1050.00', 'GBP', 1000, 7, 34, '1/1/2007');
    
    INSERT INTO FinancialApp.Sales 
    (
        id
        , amount
        , currency
        , customerId
        , employeeId
        , itemId
        , date
    )
    VALUES (2, '4500.00', 'EUR', 2000, 19, 24, '1/1/2008');

    --Execution
    SELECT amount, currency, customerId, employeeId, itemId, date
    INTO actual FROM FinancialApp.Report('USD');

    --Assertion
    CREATE TABLE expected 
    (
	    amount MONEY,
	    currency CHAR(3),
	    customerId INT,
	    employeeId INT,
	    itemId INT,
	    date DATETIME
    );

    INSERT INTO expected (amount, currency, customerId, employeeId, itemId, date) 
    SELECT 1260.00, 'USD', 1000, 7, 34, '2007-01-01';

    INSERT INTO expected (amount, currency, customerId, employeeId, itemId, date) 
    SELECT 7200.00, 'USD', 2000, 19, 24, '2008-01-01';

    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO
````
Here we’ve created a table that contains the actual results of the report and a second table containing the expected results. The AssertEqualsTable procedure will compare these two tables. If their schema or data is different, the test will fail with a report of the differences.

## Example 4: SpyProcedure

Large monolithic stored procedures are difficult to test and maintain. We want to keep our stored procedures small and focused. We also want to test our stored procedures independantly of one another. To create independent tests, we can replace the functionality of a stored procedure with a spy. The spy will record the parameters that were passed to it.

In this example, we have improved our sales report to show either current or historical data based on a parameter. Here we’ll want to test that the SalesReport procedure handles the parameter correctly and calls either HistoricalReport or CurrentReport. We’ll use the AssertEqualsTable to make sure the currency parameter is passed correctly to HistoricalReport by looking in the spy’s log.

````SQL
CREATE PROCEDURE testFinancialApp.[test that SalesReport calls HistoricalReport instead of CurrentReport when @showHistory = 1]
AS
BEGIN
    --Assemble
    EXEC tSQLt.SpyProcedure 'FinancialApp.HistoricalReport';
    EXEC tSQLt.SpyProcedure 'FinancialApp.CurrentReport';

    --Act
    EXEC FinancialApp.SalesReport 'USD', @showHistory = 1;

    SELECT currency
    INTO actual
    FROM FinancialApp.HistoricalReport_SpyProcedureLog;

    --Assert HistoricalReport got called with right parameter
    SELECT currency
    INTO expected
    FROM (SELECT 'USD') ex(currency);

    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
    
    --Assert CurrentReport did not get called
    IF EXISTS (SELECT 1 FROM FinancialApp.CurrentReport_SpyProcedureLog)
       EXEC tSQLt.Fail 'SalesReport should not have called CurrentReport when @showHistory = 1';
END;
GO
````

## Example 5: ApplyConstraint

Testing database constraints has been a difficult problem for a long time. If we have a table and want to test a single constraint, we need to insert data that satisfies all the constraints on the table. This means that as we add new constraints to a table in the future, existing constraint tests are likely to start failing.

tSQLt allows for constraints to be isolated by first faking the table (which recreates the table without the constraints) and then applying the desired constraints to the fake table. The following test case shows how the validCurrency constraint can be tested.

````SQL
CREATE PROCEDURE testFinancialApp.[test that Sales table does not allow invalid currency]
AS
BEGIN
    DECLARE @errorThrown bit; SET @errorThrown = 0;

    -- Assemble
    EXEC tSQLt.FakeTable 'FinancialApp', 'Sales';
    EXEC tSQLt.ApplyConstraint 'FinancialApp', 'Sales', 'validCurrency';

    -- Act
    BEGIN TRY
        INSERT INTO FinancialApp.Sales (id, currency)
        VALUES (1, 'XYZ');
    END TRY
    BEGIN CATCH
        SET @errorThrown = 1;
    END CATCH;    

    -- Assert
    IF (@errorThrown = 0 OR (EXISTS (SELECT 1 FROM FinancialApp.Sales)))
    BEGIN
        EXEC tSQLt.Fail 'Sales table should not allow invalid currency';
    END;
END;
GO
````

## Wrap-Up
This tutorial has provided the basics of tSQLt test case writing. Test driven database development is your gateway to more robust, higher quality databases. Databases supported by automated tests are easier to refactor, maintain and tune for performance.