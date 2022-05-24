# AssertObjectDoesNotExist

## Syntax

``` sql
tSQLt.AssertObjectDoesNotExist [@objectName = ] 'object name'
                                [, [@message = ] 'message' ]
```

## Arguments

[**@objectName** = ] ‘object name’

The name of a database object which you want to assert non-existence. @objectName is NVARCHAR(MAX) with no default.

[**@message** = ] ‘message’

Optional. String containing an additional failure message to be used if the object does not exist. @message is NVARCHAR(MAX) with no default.

## Return Code Values
Returns 0

## Error Raised
Raises a `failure` error if the specified object does exist.

## Result Sets
None

## Overview

AssertObjectDoesNotExists checks to see that an object with the specified name does not exists in the database. If the name begins with a ‘#’, indicating it is a temporary object (such as a temporary table), then tempdb is checked for the object.

## Examples

### Example: Using AssertObjectDoesNotExists to check if an object was dropped

This test case uses AssertObjectDoesNotExists to test that a stored procedure drops another stored procedure based on the supplied name.

``` sql
CREATE PROC TestTemplateUtil.[test DropProcedure drops a stored procedure]
AS
BEGIN
    EXEC('CREATE PROC dbo.MyProcedure AS RETURN 0;');

    EXEC TemplateUtil.DropProcedure 'dbo.MyProcedure';

    EXEC tSQLt.AssertObjectDoesNotExists 'dbo.MyProcedure';
END;
```
