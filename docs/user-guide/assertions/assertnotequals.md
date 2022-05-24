# AssertNotEquals

## Syntax

``` sql
tSQLt.AssertNotEquals [@expected = ] expected value
                 , [@actual = ] actual value
                [, [@message = ] 'message' ]
```

## Arguments

[**@expected** = ] expected value

The expected value for the test. @expected is SQL_VARIANT with no default.

[**@actual** = ] actual value

The actual value resulting from processing during the test. @actual is SQL_VARIANT with no default.

[**@message** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are equal. @message is NVARCHAR(MAX) with no default.

## Return Code Values

Returns 0

## Error Raised

Raises a `failure` error if expected and actual are equal.

Raises an `Operand type clash` error if the value passed for @expected or @actual is not compatible with SQL_VARIANT.

## Result Sets

None

## Overview

AssertNotEquals compares two values for inequality. If they are equal, the test case is failed; otherwise, AssertNotEquals does not affect test processing. For the purposes of AssertNotEquals, NULL is considered equal to NULL. Any non-NULL value is considered not equal to NULL.