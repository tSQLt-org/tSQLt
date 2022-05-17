# Quick Start

Okay! You read a little about tSQLt – you want to try it out! 

Now what? Here is the quickest way to get going:

## Overview

1. tSQLt requires you to enable CRL on your server. You will accomplish this by running `PrepareServer.sql` as server administrator.

2. tSQLt requires you install the tSQLt objects. You will accomplish this by running `tSQLt.class.sql` in each database.

3. tSQLt requires you to register the schema in which you will place your test stored procedures. You will acomplish this by running `tSQLt.NewTestClass 'myschema'`.

4. tSQLt requires your test names to prefix with `test` like: `myschema.test_myProcedure_EmptyValues_ReturnsZero`.
 
4. tSQLt assumes your tests are written by you as stored procedures using _assert_ capabilities in the tSQLt schema, like: `tSQLt.AssertEquals` and `tSQLt.AssertNotEquals`.

````SQL
-- a simple test
CREATE PROC myschema.test_myProcedure_EmptyValues_ReturnsZero AS
BEGIN
  -- assemble
  DECLARE @expected INT = 1;
	
  -- act
  DECLARE @actual INT = @expected + 1;
	
  -- assert
  EXEC tSQLt.AssertNotEquals @expected, @actual, 'Should not match'
END
````

5. tSQLt runs tests by calling `EXEC tSQLt.RunAll`.

## Downloading tSQLt & Installing Examples

1. Download the tSQLt zip file.

2. Unzip the file to a location on your hard drive.

3. Execute the `PrepareServer.sql` file.

 * `PrepareServer.sql` automatically enables `CLR`
   and installs a server certificate that allows 
   the installation of the tSQLt `CLR`.

 * There is no need to disable strict `CLR` security 
   on the server nor do you need to modify database 
   security settings.

 * Executing the script requires `SA` permission, 
   but needs to be done only once per server.

4. Execute the `Example.sql` file from the zip file 
   to create an example database (tSQLt_Example) 
   with tSQLt and test cases.

## Executing Examples

1. Open a new Query Editor window.

2. Execute this script:

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

4. Notice that one test is failing. 

## Installing to your Development Database

Now, let's write unit tests.

1. Install tSQLt with the `tSQLt.class.sql` script.

> Note: tSQLt should never be installed in production.

Good luck!