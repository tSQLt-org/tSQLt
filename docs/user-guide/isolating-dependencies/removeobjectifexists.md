# RemoveObjectIfExists

## Syntax

```sql
tSQLt.RemoveObjectIfExists [@ObjectName= ] 'object name'
                           [, [@NewName = ] 'new object name' OUTPUT]
```

## Arguments

[**@ObjectName =** ] ‘object name’

The name of the object to be renamed. The name should include both the schema and object name.

[**@NewName =** ] ‘new object name’ OUTPUT

The automatically generated name the object was given after being renamed. This is an output parameter only. If a value is provided here as input, it will not be used.

## Overview
`tSQLt.RemoveObjectIfExists` is a short form of `tSQLt.RemoveObject` with @IfExist = 1. See there for details.