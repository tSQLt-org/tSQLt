# AssertObjectExists

## Syntax

``` sql
tSQLt.AssertObjectExists [@objectName = ] 'object name'
                      [, [@message = ] 'message' ]
```

## Arguments

[**@objectName** = ] ‘object name’

The name of a database object which you want to assert existence. @objectName is NVARCHAR(MAX) with no default.

[**@message** = ] ‘message’

Optional. String containing an additional failure message to be used if the object does not exist. @message is NVARCHAR(MAX) with no default.

## Return Code Values
Returns 0

## Error Raised
Raises a `failure` error if the specified object does not exist.

## Result Sets
None

## Overview

AssertObjectExists checks to see if an object with the specified name exists in the database. If the object name begins with a ‘#’, indicating it is a temporary object (such as a temporary table), then tempdb is searched for the object.

## Examples

### Example: Using AssertObjectExists to check if an object was created

This test case uses AssertObjectExists to test that a stored procedure creates a new stored procedure based on the supplied table name.

``` sql
CREATE PROC TestTemplateUtil.[test CreateTableTemplate creates an update stored procedure]
AS
BEGIN
    CREATE TABLE MyTable (i INT);

    EXEC TemplateUtil.CreateTableTemplate 'MyTable';

    EXEC tSQLt.AssertObjectExists 'UpdateMyTable';
END;
```
