# Run

## Syntax
`tSQLt.Run [ [@testName = ] 'test name', [@TestResultFormatter =] 'test result formatter']`

## Arguments
`[@testName = ] ‘test name’`

Optional. The name of a test case, including the schema name to which the test case belongs. For example ‘MyTestClass.[test employee has manager]’. If not provided, the test name provided on the previous call to tSQLt.Run within the current session is used. If no test cases have been run previously in the current session, then no test cases are executed. Optionally, ‘test name’ may be the name of a test class. In which case all tests on that class are executed.

`[@TestResultFormatter = ] ‘test result formatter’`

Optional. The name of the stored procedure(accessible to tSQLt) to format the test results. DefaultTestFormatter will be used if this value is not provided. 

## Return Code Values
Returns 0

## Error Raised
Raises an error containing the test case statistics if any test fails or errors. For example, if a test case fails, the following error is raised:

```
Msg 50000, Level 16, State 10, Line 1
Test Case Summary: 117 test case(s) executed, 116 succeeded, 1 failed, 0 errored.
```

## Result Sets
None

## Overview

(Note that tSQLt requires test procedure names to start with the four letters test.)
tSQLt.Run is a flexible procedure allowing three different ways of executing test cases:

1. Providing a test class name executes all tests in that test class. If a SetUp stored procedure exists in that test class, then it is executed before each test.
2. Providing a test case name executes that single test.
3. Providing no parameter value executes tSQLt.Run the same way the previous call to tSQLt.Run was made when a parameter was provided. This essentially caches the parameter value of tSQLt.Run so that it does not need to be retyped each time.

tSQLt.Run displays a test case summary. By default, the test case summary is a text based table. However, the result format can be changed using the stored procedure, SetTestResultFormatter.

## Limitations
N/A

## Warnings
N/A

## Examples

```
-- Runs all the tests on MyTestClass
EXEC tSQLt.Run 'MyTestClass';

-- Runs [MyTestClass].[test addNumbers computes 2 plus 2 equals 4] and executes the SetUp procedure
EXEC tSQLt.Run 'MyTestClass.[test addNumbers computes 2 plus 2 equals 4]';

-- Runs using the parameter provided last time tSQLt.Run was executed
EXEC tSQLt.Run;
```
