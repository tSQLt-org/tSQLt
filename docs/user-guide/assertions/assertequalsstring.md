# AssertEqualsString

## Syntax

``` sql
tSQLt.AssertEqualsString [@expected = ] expected value
                       , [@actual = ] actual value
                      [, [@message = ] 'message' ]
```

## Arguments
[**@Expected** = ] expected value

The expected value for the test. @Expected is NVARCHAR(MAX) with no default.

[**@Actual** = ] actual value

The actual value resulting from processing during the test. @Actual is NVARCHAR(MAX) with no default.

[**@Message** = ] ‘message’

Optional. String containing an additional failure message to be used if the expected and actual values are not equal. @Message is NVARCHAR(MAX) with no default.

## Return Code Values
Returns 0

## Error Raised
Raises a `failure` error if expected and actual are not equal.

## Result Sets
None

## Overview
`tSQLt.AssertEqualsString` compares two string values for equality. If they are not equal, the test case is failed; otherwise, `tSQLt.AssertEqualsString` does not affect test processing. For the purposes of `tSQLt.AssertEqualsString`, NULL is considered equal to NULL. Any non-NULL value is considered not equal to NULL.

## Examples
### Example: AssertEqualsString to check the results of a function
This test case uses AssertEqualsString to compare the return result of a function with an expected value. The function formats a first and last name into a standard string for display.

``` sql
CREATE PROC TestPerson.[test FormatName concatenates names correctly]
AS
BEGIN
    DECLARE @expected NVARCHAR(MAX); SET @expected = 'Smith, John';
    DECLARE @actual NVARCHAR(MAX);

    SELECT @actual = person.FormatName('John', 'Smith');

    EXEC tSQLt.AssertEqualsString @expected, @actual;
END;
```

### Example: A variety of the possibilities of AssertEqualsString

The examples below show what to expect from AssertEqualsString when called with different values.

``` sql
EXEC tSQLt.AssertEqualsString 'hello', 'hello'; -- pass
EXEC tSQLt.AssertEqualsString N'goodbye', N'goodbye'; -- pass
EXEC tSQLt.AssertEqualsString 'hello', N'hello'; - pass (values are compared as NVARCHAR(MAX)

EXEC tSQLt.AssertEqualsString 'hello', NULL; -- fail
EXEC tSQLt.AssertEqualsString NULL, 'hello'; -- fail
EXEC tSQLt.AssertEqualsString NULL, NULL; -- pass
```
