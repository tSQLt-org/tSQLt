# tSQLt

Download the latest version at [tSQLt.org](http://tsqlt.org/downloads/).

tSQLt is a unit testing framework for Microsoft SQL Server. 
It is compatible with SQL Server 2005 (service pack 2 required) and above on all editions.

tSQLt allows you to implement unit tests in T-SQL. This is important as you do not have to switch between various tools to create your code and your unit tests. tSQLt also provides the following features to make it easier to create and manage unit tests:

* Tests are automatically run within transactions – this keeps tests independent and reduces any cleanup work you need
* Tests can be grouped together within a schema – allowing you to organize your tests and use common setup methods
* Output can be generated in plain text or XML – making it easier to integrate with a continuous integration tool

tSQLt is licensed under Apache 2.0 (https://github.com/tSQLt-org/tSQLt/blob/master/Build/License.txt)

## Development in the masmgr fork

`main` tracks the upstream tSQLt repository. `develop` integrates changes maintained
in this fork. Open pull requests for bug fixes and enhancements against `develop`;
keep each change in its own branch and validate it with CI before merging.

## Continuous integration

The GitHub Actions `CI` workflow runs on pushes to `develop` and `main`, pull
requests targeting either branch, and manual dispatch. It builds tSQLt with
`Build/LocalBuild.ps1` and runs the existing validation suite with
`Build/LocalValidate.ps1` against SQL Server 2017, 2019, and 2022 on Linux using
Ubuntu runners. No external service credentials or repository secrets are needed.

Open the PR checks or the repository's **Actions > CI** page to view each SQL
Server job. The run summary lists test counts, failures, errors, and skipped tests.
Validation fails on test failures or errors, missing expected result files, or an
empty test run.

Each job uploads `test-results-sql<version>` containing the result XML files,
validation output, and build/validation logs, including available files when a
step fails. These artifacts are retained for 30 days. Successful jobs also upload
`tSQLt-sql<version>` build artifacts, retained for 14 days.

CI uses a temporary self-signed key. Its build artifacts are for validation only
and must not be distributed as releases. This workflow covers Linux SQL Server;
it does not establish compatibility with Windows or other SQL Server versions.


