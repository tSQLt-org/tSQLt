# ApplyConstraint
## Syntax

``` sql
tSQLt.ApplyConstraint [@TableName = ] 'table name'
                    , [@ConstraintName = ] 'constraint name'
                    , [@SchemaName = ] 'schema name'
```

## Arguments

[**@TableName** = ] ‘table name’

The name of the table where the constraint should be applied. Should contain both the schema name and the table name.

[**@ConstraintName** = ] ‘constraint name’

The name of the constraint to be applied. Should not include the schema name or table name.

[**@SchemaName** = ] ‘schema name’ – **Deprecated: do not use, will be removed in future version**

## Return code values
Returns 0

## Error raised

If the specified table or constraint does not exist an error is thrown: ApplyConstraint could not resolve the object names, ‘%s’, ‘%s’.

## Result sets
None

## Overview
We want to be able to test constraints individually. We can use FakeTable to remove all the constraints on a table, and ApplyConstraint to add back in the one which we want to test.

ApplyConstraint in combination with FakeTable allows constraints to be tested in isolation of other constraints on a table.

## Limitations
ApplyConstraint works with the following constraint types:

- CHECK constraints
- FOREIGN KEY constraints
- UNIQUE constraints
- PRIMARY KEY constraints

There are the following limitations:

- Cascade properties of FOREIGN KEY constraints are not preserved.
- SQL Server automatically creates unique indexes for UNIQUE and PRIMARY KEY constraints. Those indexes for “applied” constraints do not preserve asc/desc properties of the original supporting indexes.

Note: Applying a PRIMARY KEY constraint will automatically change the involved columns of the faked table to be “NOT NULL”able.

## Examples
**Example: Using ApplyConstraint to test a Foreign Key Constraint**

In this example, we have a foreign key constraint on the ReferencingTable. We would like to test this constraint and have two test cases.

The first test ensures that the foreign key prevents inappropriate inserts. It does this by faking the two tables involved and then calling ApplyConstraint. Then an attempt is made to insert a record into the ReferencingTable with no record in the ReferencedTable. The exception is caught and the test passes or fails based on this exception.

The second test makes sure that appropriate records can be inserted. Again, the two tables are faked and ApplyConstraint is called. If any exception is thrown when we attempt to insert a record into ReferencingTable, the test will fail (because any uncaught exception will cause a test to fail).

``` sql
EXEC tSQLt.NewTestClass 'ConstraintTests';
GO

CREATE PROCEDURE ConstraintTests.[test ReferencingTable_ReferencedTable_FK prevents insert of orphaned rows]
AS
BEGIN
     EXEC tSQLt.FakeTable 'dbo.ReferencedTable';
     EXEC tSQLt.FakeTable 'dbo.ReferencingTable';
     
     EXEC tSQLt.ApplyConstraint 'dbo.ReferencingTable','ReferencingTable_ReferencedTable_FK';
     
     DECLARE @ErrorMessage NVARCHAR(MAX); SET @ErrorMessage = '';
     
     BEGIN TRY
    INSERT  INTO dbo.ReferencingTable
            ( id, ReferencedTableId )
    VALUES  ( 1, 11 ) ;
     END TRY
     BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();     
     END CATCH
     
     IF @ErrorMessage NOT LIKE '%ReferencingTable_ReferencedTable_FK%'
     BEGIN
       EXEC tSQLt.Fail 'Expected error message containing ''ReferencingTable_ReferencedTable_FK'' but got: ''',@ErrorMessage,'''!';
     END
     
END
GO

CREATE PROCEDURE ConstraintTests.[test ReferencingTable_ReferencedTable_FK allows insert of non-orphaned rows]
AS
BEGIN
     EXEC tSQLt.FakeTable 'dbo.ReferencedTable';
     EXEC tSQLt.FakeTable 'dbo.ReferencingTable';
     
     EXEC tSQLt.ApplyConstraint 'dbo.ReferencingTable','ReferencingTable_ReferencedTable_FK';
     
  INSERT  INTO dbo.ReferencedTable
          ( id )
  VALUES  ( 11 ) ;
  INSERT  INTO dbo.ReferencingTable
          ( id, ReferencedTableId )
  VALUES  ( 1, 11 ) ;
END
GO
```