# SpyProcedure

## Syntax

```sql
tSQLt.SpyProcedure [@ProcedureName = ] 'procedure name'
                [, [@CommandToExecute = ] 'command' ]
```

## Arguments
[**@ProcedureName =** ] ‘procedure name’

The name of an existing stored procedure. @ProcedureName is NVARCHAR(MAX) with no default. @ProcedureName should include the schema name of the stored procedure. For example:
MySchema.MyProcedure

[**@CommandToExecute =** ] ‘command’

An optional command to execute when a call to Procedure Name is made. @CommandToExecute is NVARCHAR(MAX) with no default.

## Return Code Values

Returns 0

## Error Raised

If the procedure contains more than 1020 parameters, SpyProcedure cannot be used and the following error is raised: Cannot use SpyProcedure on procedure ‘procedure name’ because it contains more than 1020 parameters.

If the object given by procedure name does not exist or is not a stored procedure, the follow error is raised: Cannot use SpyProcedure on ‘procedure name’ because the procedure does not exist.

## Result Sets

None

## Overview

Large monolithic stored procedures are difficult to test and maintain. We want to keep our stored procedures small and focused. We also want to test our stored procedures independently of one another. To create independent tests, we can replace the functionality of a stored procedure with a spy. The spy will record the parameters that were passed to it.

SpyProcedure allows tests to be written for a procedure in isolation of the other procedures that it calls. SpyProcedure creates a table with the name of @ProcedureName + ‘_SpyProcedureLog’. This table contains an identity column ‘_id_’ and a column for each procedure parameter (except for cursor output parameters). SpyProcedure also replaces the procedure named by @ProcedureName with the command provided in the @CommandToExecute parameter and a command to insert the parameter values into the SpyProcedureLog table.

Therefore, whenever the @ProcedureName is executed during the test instead of actually running the procedure, a new log entry is made in the @ProcedureName_SpyProcedureLog table and @CommandToExecute is called.

## Limitations
SpyProcedure can not be used with temporary stored procedures (stored procedures whose name begins with #).

SpyProcedure can not be used with procedures which have more than 1020 columns.

## Warnings

Remember that if you are spying a procedure, you are not testing that procedure. Your test is trying to test something else: typically, another procedure’s interaction with the procedure you are spying.

## Examples

**Example: Using SpyProcedure to record parameters passed to a procedure**

In this example, we have a sales report which will show either current or historical data based on a parameter. Here we’ll want to test that the SalesReport procedure handles the parameter correctly and calls either HistoricalReport or CurrentReport. We’ll use the assertEqualsTable to make sure the currency parameter is passed correctly to HistoricalReport by looking in the spy’s log.

```sql
CREATE PROCEDURE testFinancialApp.[test that SalesReport calls HistoricalReport when @showHistory = 1]
AS
BEGIN
-------Assemble
    EXEC tSQLt.SpyProcedure 'FinancialApp.HistoricalReport';
    EXEC tSQLt.SpyProcedure 'FinancialApp.CurrentReport';

-------Act
    EXEC FinancialApp.SalesReport 'USD', @showHistory = 1;

    SELECT currency
      INTO actual
      FROM FinancialApp.HistoricalReport_SpyProcedureLog;

-------Assert HistoricalReport got called with right parameter
    SELECT currency
      INTO expected
      FROM (SELECT 'USD') ex(currency);

    EXEC tSQLt.AssertEqualsTable 'actual', 'expected';

-------Assert CurrentReport did not get called
    IF EXISTS (SELECT 1 FROM FinancialApp.CurrentReport_SpyProcedureLog)
       EXEC tSQLt.Fail 'SalesReport should not have called CurrentReport when @showHistory = 1';
END;
GO
```

**Example: Using SpyProcedure to return a hard-coded set of output parameter values**

Suppose we want to test the procedure, IsDiskSpaceTooLow, which returns a 0 if there is enough disk space, and -1 if there is not enough disk space. IsDiskSpaceTooLow conveniently calls another procedure, GetDiskSpace which returns an output parameter for the current disk space. Since setting up a test to fill the drive to a certain size is probably a bad idea, we can test IsDiskSpaceTooLow by using SpyProcedure on GetDiskSpace and hard-coding the output parameter for the purposes of the test.

```sql
CREATE PROCEDURE DiskUtil.GetDiskSpace @DiskSpace INT OUT
AS
BEGIN
    -- This procedure does something to return the disk space as @DiskSpace output parameter
END
GO

CREATE PROCEDURE DiskUtil.IsDriveSpaceTooLow
AS
BEGIN
    DECLARE @DiskSpace INT;
    EXEC DiskUtil.GetDiskSpace @DiskSpace = @DiskSpace OUT;

    IF @DiskSpace < 512
        RETURN -1;
    ELSE
        RETURN 0;
END;
GO

CREATE PROCEDURE testDiskUtil.[test IsDriveSpaceTooLow returns -1 if drive space is less than 512 MB]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'DiskUtil.GetDiskSpace', 'SET @DiskSpace = 511';

    DECLARE @ReturnValue INT;
    EXEC @ReturnValue = DiskUtil.IsDriveSpaceTooLow;

    EXEC tSQLt.AssertEquals -1, @ReturnValue;
END
GO
```