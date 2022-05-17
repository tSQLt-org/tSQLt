# DropClass

## Syntax
`tSQLt.DropClass [@ClassName = ] 'class name'`

## Arguments
[@ClassName = ] ‘class name’
The name of the class (schema) to be dropped

## Return Code Values
Returns 0

## Error Raised
An error may be raised if the test class already exists and an object belonging to it cannot be dropped.

## Result Sets
None

## Overview
tSQLt.DropClass drops a schema and all objects belonging to it. If the schema does not exist, nothing happens.

## Limitations
N/A

## Warnings
Care should be used when executing tSQLt.DropClass as it drops a schema and all objects on that schema.

## Examples
Example: Creating a test class and the dropping it

```
EXEC tSQLt.NewTestClass 'testFinancialApp';
GO

EXEC tSQLt.DropClass 'testFinancialApp';
GO
```