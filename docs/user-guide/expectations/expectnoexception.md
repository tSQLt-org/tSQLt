# ExpectNoException

## Syntax
```sql 
tSQLt.ExpectNoException [ [@Message= ] 'supplemental fail message']
```

## Arguments
[**@Message =** ] ‘supplemental fail message’

Optional. Supplemental information to clarify the test’s intent. This is displayed in case of a failure.

## Return Code Values
Returns 0

## Errors Raised
Raises a `failure` error if any error is raised after it was called.

## Result Sets
None

## Overview
`tSQLt.ExpectNoException` marks the point in the test after which no error should be raised. `tSQLt.ExpectNoException` specifies that the intention of the test is to assert that no error is raised. Therefore the test will fail instead of error, if an error is encountered after `tSQLt.ExpectNoException` was called.

There can be only one call to `tSQLt.ExpectNoException` per test. However, a call to `tSQLt.ExpectNoException` can be followed by a call to `tSQLt.ExpectException`.

## Examples
**Example: Using `tSQLt.ExpectNoException` to assert that no error is raised**

```sql
CREATE PROCEDURE PurgeTableTests.[test dbo.PurgeTableIfExists ignores not existing table]
AS
BEGIN
  EXEC tSQLt.ExpectNoException;
  EXEC dbo.PurgeTableIfExists @TableName='dbo.DoesNotExist';
END;
GO
```