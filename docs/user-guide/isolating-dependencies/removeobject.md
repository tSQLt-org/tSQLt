# RemoveObject

## Syntax

```sql
tSQLt.RemoveObject [@ObjectName= ] 'object name'
                [, [@NewName = ] 'new object name' OUTPUT]
                [, [@IfExists = ] ( 0 | 1 )]
```

## Arguments

[**@ObjectName =** ] ‘object name’

The name of the object to be renamed. The name should include both the schema and object name.

[**@NewName =** ] ‘new object name’ OUTPUT

The automatically generated name the object was given after being renamed. This is an output parameter only. If a value is provided here as input, it will not be used.

[**@IfExists =** ] ( 0 | 1 )

If @IfExists = 0 is passed, an error is raised if the object does not exist. @IfExists = 1 causes tSQLt.RemoveObject to be a NoOp if the object does not exist. The default is 0.

## Return Code Values

Returns 0

## Error Raised

If the specified object does not exist an error is thrown: %s does not exist.

## Result Sets

None

## Overview
Often times an object needs to be replaced with a mock. The first step in replacing an object with a mock is to remove the original object. tSQLt.RemoveObject removes the original object by renaming it. The new name for the object is automatically generated to avoid collisions with other objects.

For tables and stored procedures, please refer to [FakeTable](faketable.md) and [SpyProcedure](spyprocedure.md), respectively.

## Examples

**Example: Replacing a function with a stub**

In this example, we are testing that GetRecentUsers view returns only users from the past 10 minutes. In this example, we have a util.GetCurrentDate function which returns the current date and is used by GetRecentUsers. For the purposes of our test, we want to return a constant date. RemoveObject is called so that we can create a stub function which returns a hard-coded value.

```sql
CREATE PROCEDURE GetRecentUsersTests.[test that GetRecentUsers returns users from the past 10 minutes]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Users';
    INSERT INTO dbo.Users (username, startdate) VALUES ('bob', '2013-03-15 11:59:59');
    INSERT INTO dbo.Users (username, startdate) VALUES ('joe', '2013-03-15 12:00:00');
    INSERT INTO dbo.Users (username, startdate) VALUES ('sue', '2013-03-15 12:01:00');

    EXEC tSQLt.RemoveObject 'util.GetCurrentDate';
    EXEC ('CREATE FUNCTION util.GetCurrentDate() RETURNS datetime AS BEGIN RETURN ''2013-03-15 12:10:00''; END;');

    SELECT username, startdate
      INTO #Actual
      FROM dbo.GetRecentUsers;

    SELECT TOP(0) *
      INTO #Expected
      FROM #Actual;

    INSERT INTO #Expected (username, startdate) VALUES ('joe', '2013-03-15 12:00:00');
    INSERT INTO #Expected (username, startdate) VALUES ('sue', '2013-03-15 12:01:00');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
```