# Quick Start


## 1. Prepare your server
tSQLt requires you to enable CRL on your server. You will accomplish this by 
running `PrepareServer.sql` as server administrator. What exactly is SQL Server 
CLR? Learn more [here](https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/common-language-runtime-integration-overview?view=sql-server-ver15).

**What to do:**
1. Load `PrepareServer.sql` in your Query window
1. Connect to your server 
1. Execute the entire script

 * `PrepareServer.sql` automatically enables `CLR`
   and installs a server certificate that allows 
   the installation of the tSQLt `CLR`.
 * There is no need to disable strict `CLR` security 
   on the server nor do you need to modify database 
   security settings.
 * Executing the script requires `SA` permission, 
   but needs to be done only once per server.

## 2. Prepare your database
tSQLt requires you install the tSQLt objects. You will accomplish this by running 
`tSQLt.class.sql` in each database. What exactly does class.sql do? Learn more 
[here](https://github.com/tSQLt-org/tSQLt/blob/main/Source/tSQLt.class.sql). 

**What to do:**
1. Load `tSQLt.class.sql` in your Query window
1. Connect to your server 
1. Execute the entire script

## 3. Register your schema
tSQLt requires you to register the schema in which you will place your test 
stored procedures. You will acomplish this by running `tSQLt.NewTestClass 'tests'`.
````SQL
EXEC tSQLt.NewTestClass 'tests'
````

## 4. Write your first test
1. tSQLt requires your test names to prefix with `test` like: `tests.test_MyFirstTest_AddTwoValues_ShouldMatch`.
1. tSQLt assumes your tests are written by you as stored procedures using _assert_ capabilities in the tSQLt schema, like: `tSQLt.AssertEquals` and `tSQLt.AssertNotEquals`.

````SQL
-- a simple test
CREATE PROC tests.test_MyFirstTest_AddTwoValues_ShouldMatch AS
BEGIN
  -- assemble
  DECLARE @expected INT = 1;
	
  -- act
  DECLARE @actual INT = @expected + 1;
	
  -- assert
  EXEC tSQLt.AssertNotEquals @expected, @actual, 'Should not match'
END
````

## 5. Run your tests
tSQLt runs tests by calling `EXEC tSQLt.RunAll`. Remember, tSQLt only works 1) on servers prepared for tests, 2) on databases where tSQLT is installed, 3) then looks in your registered scehemas 4) for test procedures prefixed with `test`.
````SQL
EXEC tSQLt.RunAll
````

# Built-in Examples
tSQLt comes with example tests to illustrate some advanced capabilities.

## Download & Set up 

1. Download the tSQLt zip file.

2. Unzip to a location on your hard drive.

3. Execute the `PrepareServer.sql` file.

	**What to do:**
	1. Load `PrepareServer.sql` in your Query window
	1. Connect to your server 
	1. Execute the entire script

4. Execute the `Example.sql` file from the zip file 
   to create an example database (tSQLt_Example) 
   with tSQLt and test cases.

   **What to do:**
	1. Load `Example.sql` in your Query window
	1. Connect to your server 
	1. Execute the entire script

## Execute examples

1. Open a new Query Editor window.

2. Execute `RunAll`:

````SQL
EXEC tSQLt.RunAll
````

3. You will see this output:

````
[AcceleratorTests].[test ready for experimentation if 2 particles] failed: Expected: <1> but was: <0>

+----------------------+
|Test Execution Summary|
+----------------------+ 
|No|Test Case Name                                                                                            |Result |
+--+----------------------------------------------------------------------------------------------------------+-------+
|1 |[AcceleratorTests].[test a particle is included only if it fits inside the boundaries of the rectangle]   |Success|
|2 |[AcceleratorTests].[test a particle within the rectangle is returned with an Id, Point Location and Value]|Success|
|3 |[AcceleratorTests].[test a particle within the rectangle is returned]                                     |Success|
|4 |[AcceleratorTests].[test email is not sent if we detected something other than higgs-boson]               |Success|
|5 |[AcceleratorTests].[test email is sent if we detected a higgs-boson]                                      |Success|
|6 |[AcceleratorTests].[test foreign key is not violated if Particle color is in Color table]                 |Success|
|7 |[AcceleratorTests].[test foreign key violated if Particle color is not in Color table]                    |Success|
|8 |[AcceleratorTests].[test no particles are in a rectangle when there are no particles in the table]        |Success|
|9 |[AcceleratorTests].[test status message includes the number of particles]                                 |Success|
|10|[AcceleratorTests].[test we are not ready for experimentation if there is only 1 particle]                |Success|
|11|[AcceleratorTests].[test ready for experimentation if 2 particles]                                        |Failure|
-------------------------------------------------------------------------------
Msg 50000, Level 16, State 10, Line 1
Test Case Summary: 11 test case(s) executed, 10 succeeded, 1 failed, 0 errored.
-------------------------------------------------------------------------------

````

4. Notice one test is intentionally failing. Check it out. 


## Important Reminder
tSQLt should never be installed in production.