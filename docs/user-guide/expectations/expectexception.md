# ExpectException
## Syntax

``` sql
tSQLt.ExpectException 
                     [  [@ExpectedMessage= ] 'expected error message']
                     [, [@ExpectedSeverity= ] 'expected error severity']
                     [, [@ExpectedState= ] 'expected error state']
                     [, [@Message= ] 'supplemental fail message']
                     [, [@ExpectedMessagePattern= ] 'expected error message pattern']
                     [, [@ExpectedErrorNumber= ] 'expected error number']
```

## Arguments

[**@ExpectedMessage** = ] ‘expected error message’

Optional. The expected error message. The test fails if an error with a different message is thrown.

[**@ExpectedSeverity** = ] ‘expected error severity’

Optional. The expected error severity. The test fails if an error with a different severity is thrown.

[**@ExpectedState** = ] ‘expected error state’

Optional. The expected error state. The test fails if an error with a different state is thrown.

[**@Message** = ] ‘supplemental fail message’

Optional. Supplemental information to clarify the test’s intent. This is displayed in case of a failure.

[**@ExpectedMessagePattern** = ] ‘expected error message pattern’

Optional. A pattern describing the expected error message. The test fails if an error with a message not matching this pattern is thrown.

[**@ExpectedErrorNumber** = ] ‘expected error number’

Optional. The expected error number. The test fails if an error with a different number is thrown.

## Return code values

Returns 0

## Errors raised
Raises a `failure` error if an error matching the expectation is not raised.

## Result sets
None

## Overview

`tSQLt.ExpectException` marks the point in the test after which an error should be raised. All parameters are optional. Independent of the supplied parameters, the test fails if after the `tSQLt.ExpectException` call no error is raised. Passing in a NULL in any parameter has the same effect as omitting that parameter.

The parameters allow to constrain the expected exception further.

There can be only one call to `tSQLt.ExpectException` per test. However, a call to `tSQLt.ExpectException` can follow a call to `tSQLt.ExpectNoException`.

## Examples
There are two main call patterns:

``` sql
EXEC tSQLt.ExpectException @ExpectedMessage = 'Some Expected Message', @ExpectedSeverity = NULL, @ExpectedState = NULL;
```
and

``` sql
EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Part of Expected Message%', @ExpectedSeverity = NULL, @ExpectedState = NULL;
```

**Example: Using `tSQLt.ExpectException` to check that correct error is raised**

``` sql
CREATE PROCEDURE PurgeTableTests.[test dbo.PurgeTable rejects not existing table]
AS
BEGIN
  EXEC tSQLt.ExpectException @Message = 'Table dbo.DoesNotExist not found.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC dbo.PurgeTable @TableName='dbo.DoesNotExist';
END;
GO
```
