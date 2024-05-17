# <param name="execute.sql.filename" value="temp/Validate/tSQLt.tests/Drop(master.tSQLt_testutil).sql" />
# <param name="execute.sql.filename" value="temp/Validate/tSQLt.tests/temp_create_example.sql" />
# <param name="execute.sql.statement" value="EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;" />
# <param name="execute.sql.outputfile" value="temp/Validate/TestResults/TestResults_Example.xml" />
#     <param name="execute.sql.testcasefilename" value="ExampleDB" />
#     <param name="execute.sql.statement" value="PRINT DB_NAME();EXEC tSQLt.Run 'ExampleDeployed';" />
# <param name="execute.sql.statement" value="EXEC tSQLt.SetSummaryError @SummaryError=1;EXEC tSQLt_testutil.CheckMultiRunResults @noError=1;EXEC tSQLt_testutil.StoreBuildLog @TableName='${logtable.name}',@RunGroup='Example';" />

$TestDbName = 'tSQLt_Example';

Log-Output("Run All Tests... Cleanup master ...")
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Elevated = $true
    Files = @(
        (Join-Path $TestsPath "Drop(master.tSQLt_testutil).sql" | Resolve-Path)
    )
    DatabaseName = "tempdb"
    AdditionalParameters = @{NewDbName = $TestDbName}
}
Invoke-SQLFileOrQuery @parameters;

Log-Output("Run All Tests... Create Database $TestDbName and deploy example code ...")
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Elevated = $true
    Files = @(
        (Join-Path $TestsPath "temp_create_example.sql" | Resolve-Path)
    )
    DatabaseName = "tempdb"
    AdditionalParameters = @{NewDbName = $TestDbName}
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Set SummaryError Off, PrepMultiRun...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Query = "EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;"
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... TestUtil Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    TestFilePath = (Join-Path $TestsPath "TestThatExamplesAreDeployed.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_Example.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... Set SummaryError O, Capture MultiRun Results...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Query = "EXEC tSQLt.SetSummaryError @SummaryError=1;EXEC tSQLt_testutil.CheckMultiRunResults @noError=1;EXEC tSQLt_testutil.StoreBuildLog @TableName='$LogTableName',@RunGroup='AllTests_Example';"
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;
