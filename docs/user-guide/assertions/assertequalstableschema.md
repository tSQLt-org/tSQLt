# AssertEqualsTableSchema

## Syntax

``` sql
tSQLt.AssertEqualsTableSchema [@Expected = ] 'expected table name'
                            , [@Actual = ] 'actual table name'
                           [, [@FailMsg = ] 'message' ]
```

## Arguments
[**@Expected** = ] expected table name

The name of a table with the expected columns (and data types). @Expected is NVARCHAR(MAX) with no default.

[**@Actual** = ] actual table name

The name of a table created as the result from processing during the test. @Actual is NVARCHAR(MAX) with no default.

[**@FailMsg** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @FailMsg is NVARCHAR(MAX) with a default of ‘unexpected/missing resultset rows!’.

## Return Code Values
Returns 0

## Errors Raised
Raises a `failure` error if the contents of the expected table and the actual table are not equal.

## Result Sets
None

## Overview
`tSQLt.AssertEqualsTableSchema` works like `tSQLt.AssertEqualsTable`, but it compares the table structure instead of the table contents.

Under the hood, `tSQLt.AssertEqualsTableSchema` calls `tSQLt.AssertEqualsTable` on the table metadata. For details of how to interpret its output, check out the `tSQLt.AssertEqualsTable` [documentation](assertequalstable.md).
