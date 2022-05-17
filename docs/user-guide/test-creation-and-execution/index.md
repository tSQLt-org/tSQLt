# Test Creation and Execution

This section describes how test cases are created and executed.

We’re going to answer two important questions in this section, “What happens when you create a test class?” and “What happens when a test class gets executed?”

## What happens when you create a test class?
Not much. When you create a test class using `tSQLt.NewTestClass`, a schema is created. That schema is created with an extended property so that tSQLt can later figure out which schemas are test classes. ___Note:___ _If there is already a schema with the same name as the one you are trying to create, it is dropped first._

## What happens when a test class gets executed?
If you execute `tSQLt.RunTestClass`, tSQLt does the following things:

1. It looks at all the stored procedures in the test class (schema) that start with the word “test”. These are all considered to be all the test cases for that test class.
1. For each of the test cases:
   1. A record is created indicating that the test case is being executed in the tSQLt.TestResult table.
   1. tSQLt starts a transaction.
   1. If there is a stored procedure named SetUp on the test class, it is executed.
   1. The test case stored procedure is executed.
   1. The transaction is rolled-back.
   1. The record in tSQLt.TestResult is updated accordingly if the test case succeeded, failed or threw an error.
1. The test results are displayed in the console.

If you execute `tSQLt.RunAll`, tSQLt first looks at all the schemas in the database for ones marked as test classes. Then, it follows steps 1 and 2 above for each test class. The test results are displayed after running all test classes.

## Summary
Create test classes using `tSQLt.NewTestClass`. Execute test classes using `tSQLt.RunTestClass` or `tSQLt.RunAll`. When individual test cases are executed, they are wrapped in a transaction which is rolled-back. Before each test case, SetUp is called if it exists on the test class.