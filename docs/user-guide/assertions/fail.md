# Fail

## Syntax

``` sql
tSQLt.Fail [ [@Message0 = ] message part ]
          [, [@Message1 = ] message part ]
          [, [@Message2 = ] message part ]
          [, [@Message3 = ] message part ]
          [, [@Message4 = ] message part ]
          [, [@Message5 = ] message part ]
          [, [@Message6 = ] message part ]
          [, [@Message7 = ] message part ]
          [, [@Message8 = ] message part ]
          [, [@Message9 = ] message part ]
```

## Arguments

[**@Message0 – @Message9** = ] message part

Optional. The message parts contain the message which will be displayed as the failure message for the test case. Multiple parameters are provided so that the caller does not have to first build up a string variable to pass to the fail procedure. All @Message parameters are NVARCHAR(MAX) with a default of an empty string.


## Return Code Values

Returns 0

## Error Raised

Raises a `failure` error when called, resulting in failure of the test case.

## Result Sets

None

## Overview

Fail simply fails a test case with the specified failure message. Frequently, use of one of the tSQLt.Assert… procedures is more appropriate. However, there are times when calling Fail is the only option or more convenient.

## Examples

### Example: Using Fail to check that a randomly generated number is in the expected range

This test case repeatedly calls a random number generator. If the generated random number is ever outside of the specified range, the test case is failed using the tSQLt.Fail procedure. This example also demonstrates passing multiple message parameters to Fail:

``` sql
CREATE PROCEDURE testRandom.[test GetRandomInt(1,10) does not produce values less than 1 or greater than 10]
AS
BEGIN
    SET NOCOUNT ON;

    EXEC Random.SeedRandomOnTime;

    DECLARE @numTrials INT; SET @numTrials = 10000;
    DECLARE @i INT; SET @i = 0;
    DECLARE @r INT;

    WHILE @i < @numTrials
    BEGIN
        EXEC Random.GetRandomInt 1, 10, @r OUTPUT;
        IF @r < 1 OR @r > 10
        BEGIN
            EXEC tSQLt.Fail 'Invalid random value returned: ', @r;
        END;

        SET @i = @i + 1;
    END;
END;
GO
```
