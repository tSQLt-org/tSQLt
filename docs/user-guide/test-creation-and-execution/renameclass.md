# RenameClass

## Syntax
`tSQLt.RenameClass [@SchemaName = ] 'class name'
                , [@NewSchemaName = ] 'new class name'`

## Arguments
`[@SchemaName = ] ‘class name’
The name of the class (schema) to be renamed
[@NewSchemaName = ] ‘new class name’
The new name of the test class (schema)`

## Return Code Values
Returns 0

## Error Raised
An error may be raised if an object on the test class cannot be transferred to the new test class.

## Result Sets
None

## Overview

tSQLt.RenameClass creates a new test class schema. All objects from the original test class schema are tranfered to the new test class schema. The original test class schema is then dropped.

## Limitations
N/A

## Warnings
N/A

## Examples

Example: Creating and then renaming a test class

```EXEC tSQLt.NewTestClass 'testFinancialApp';
GO

EXEC tSQLt.RenameClass 'testFinancialApp', 'FinancialAppTests';
GO```
