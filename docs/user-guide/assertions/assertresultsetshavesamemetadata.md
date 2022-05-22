# AssertResultSetsHaveSameMetaData

## Syntax

``` sql
tSQLt.AssertResultSetsHaveSameMetaData [@expectedCommand = ] 'expected command'
                                     , [@actualCommand = ] 'actual command'
```

## Arguments

[**@expectedCommand** = ] ‘expected command’

A command which returns a result set with the expected meta data to compare with. @expectedCommand is NVARCHAR(MAX) with no default.

[**@actualCommand** = ] ‘actual command’

The actual result set whose meta data should be compared with the meta data of the result set from the expected command. @actualCommand is NVARCHAR(MAX) with no default.

## Return Code Values
Returns 0

## Error Raised
Raises a `failure` error if the meta data of the expected command and the meta data of the actual command are not equal.

## Result Sets
None

## Overview

AssertResultSetsHaveSameMetaData executes the expected command and actual command, capturing the result sets from each. The meta data (i.e. the column names and properties) are compared between the two result sets. If they meta data contains differences, then AssertResultSetsHaveSameMetaData fails the test.

This may be useful, for example, when testing a stored procedure which returns a result set and the names and data types of the columns should be validated.

## Examples

## Example: AssertResultSetsHaveSameMetaData to check the meta data properties of a view

This test case uses AssertResultSetsHaveSameMetaData to check that the meta data of the EmployeeAgeReport view. The view’s meta data is compared against a query provided in the @expectedCommand parameter.

``` sql
CREATE PROC TestHumanResources.[test EmployeeAgeReport has appropriate meta data]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''A'' AS VARCHAR(1000)) AS name, CAST(30 AS SMALLINT) AS age',
        'SELECT name, age FROM HumanResources.EmployeeAgeReport';
END;
```
