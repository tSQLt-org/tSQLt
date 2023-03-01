# RunAll

## Syntax
`tSQLt.RunAll`

## Arguments
none

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
tSQLt.RunAll executes all tests in all test classes created with tSQLt.NewTestClass in the current database. If the test class schema contains a stored procedure called SetUp, it is executed before calling each test case. The name of each test case stored procedure must begin with ‘test’. RunAll displays a test case summary. By default, the test case summary is a text based table. However, the result format can be changed using the stored procedure, SetTestResultFormatter.

## Limitations
N/A

## Warnings
N/A