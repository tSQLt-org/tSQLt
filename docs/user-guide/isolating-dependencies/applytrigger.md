# ApplyTrigger
## Syntax

``` sql
tSQLt.ApplyTrigger [@TableName = ] 'table name'
                    , [@TriggerName = ] 'trigger name'
```

## Arguments

[**@TableName** = ] ‘table name’
The name of the table where the constraint should be applied. Should contain both the schema name and the table name.

[**@TriggerName** = ] ‘trigger name’

The name of the trigger to be applied. Should not include the schema name or table name.

## Return code values
Returns 0

## Error raised
If the specified table or trigger does not exist an error is thrown.

## Result sets
None

## Overview
We want to be able to test triggers individually. We can use FakeTable to remove all the constraints and triggers from a table, and ApplyTrigger to add back in the one which we want to test.

ApplyTrigger in combination with FakeTable allows triggers to be tested in isolation of constraints and other triggers on a table.

## Examples
**Example: Using ApplyTrigger to test a trigger**

In this example, the test isolates the AuditInserts trigger from other constraints and triggers on the Registry.Student table. This allows us to test that the trigger inserts a record into the Logs.Audit table when a new student is inserted into the Student table.

``` sql
EXEC tSQLt.NewTestClass 'AuditTests';
GO

CREATE PROCEDURE AuditTests.[test inserting record into Student table creates Audit record]
AS
BEGIN
  EXEC tSQLt.FakeTable 'Registry.Student';
  EXEC tSQLt.FakeTable @TableName = 'Logs.Audit';
  EXEC tSQLt.ApplyTrigger 'Registry.Student', 'AuditInserts';
  
  INSERT INTO Registry.Student (StudentId) VALUES (1);
  
  SELECT LogMessage
  INTO #Actual
  FROM Logs.Audit;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('Student record created, id = 1');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
```