# AssertLike

## Syntax

``` sql
tSQLt.AssertLike [@ExpectedPattern = ] expected pattern
               , [@Actual = ] actual value
              [, [@Message = ] 'message' ]
```

## Arguments

[**@ExpectedPattern** = ] expected pattern

An NVARCHAR pattern that may contain regular characters and wildcard characters. ExpectedPattern uses the same pattern syntax as the SQL LIKE keyword.

[**@Actual** = ] actual value

The actual value resulting from processing during the test. @Actual is an NVARCHAR(MAX) with no default.

[**@Message** = ] ‘message’

Optional. String containing an additional failure message to be used if ExpectedPattern does not match the specified actual value. @message is NVARCHAR(MAX) with no default.

## Return Code Values

Returns 0

## Error Raised

Raises a `failure` error if the expected pattern does not match the actual value provided.

Raises an `@ExpectedPattern may not exceed 4000 characters` error if the value passed for @ExpectedPattern is more than 4000 characters in length. This is due to a limitation in SQL Server’s LIKE keyword.

## Result Sets

None

## Overview

`tSQLt.AssertLike` checks if the actual value matches the expected pattern. If it does not match, the test case is failed; otherwise, `tSQLt.AssertLike` does not affect test processing. For the purposes of `tSQLt.AssertLike`, NULL is considered LIKE to NULL. Any non-NULL value is considered not LIKE to NULL.

## Examples

### Example: AssertLike to check the results of a function

This test case uses AssertLike to compare the return result of a function with an expected value.

``` sql
CREATE PROC TestPerson.[test FormatName concatenates names correctly]
AS
BEGIN
    DECLARE @actual NVARCHAR(MAX);

    SELECT @actual = person.FormatName('John', 'Smith');

    EXEC tSQLt.AssertLike 'John%Smith', @actual;
END;
```

### Example: A variety of the possibilities of AssertLike

The examples below show what to expect from AssertLike when called with different values.

``` sql
EXEC tSQLt.AssertLike 'hello', 'hello'; -- pass
EXEC tSQLt.AssertLike '%el%', 'hello'; - pass
EXEC tSQLt.AssertLike 'h_llo', 'hello'; - pass
EXEC tSQLt.AssertLike '%oo%', 'hello'; - fail

EXEC tSQLt.AssertLike 'hello', NULL; -- fail
EXEC tSQLt.AssertLike NULL, 'hello'; -- fail
EXEC tSQLt.AssertLike NULL, NULL; -- pass
```
