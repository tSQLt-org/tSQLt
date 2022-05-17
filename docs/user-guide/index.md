# User Guide

This reference contains an explanation of each of the public tables, views, stored procedures and functions provided by tSQLt.

## Test creation and execution

- NewTestClass
- DropClass
- RunAll
- Run
- RenameClass

## Assertions

- AssertEmptyTable
- AssertEquals
- AssertEqualsString
- AssertEqualsTable
- AssertEqualsTableSchema
- AssertNotEquals
- AssertObjectDoesNotExist
- AssertObjectExists
- AssertResultSetsHaveSameMetaData
- Fail
- AssertLike

## Expectations

- ExpectException
- ExpectNoException

## Isolating dependencies

- ApplyConstraint
- FakeFunction
- FakeTable
- RemoveObjectIfExists
- SpyProcedure
- ApplyTrigger
- RemoveObject