Log-Output("Run All Tests... Create Database $TestDbName ...")
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Elevated = $true
    Files = @(
        (Join-Path $TestsPath "CreateBuildDb.sql" | Resolve-Path)
    )
    DatabaseName = "tempdb"
    AdditionalParameters = @{NewDbName = $TestDbName}
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Install tSQLt...')
if($DeploySource -eq "class"){
    Log-Output('Deploying tSQLt from tSQLt.class.sql...')
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        Files = @(
            (Join-Path $SourcePath "tSQLt.class.sql" | Resolve-Path)
        )
        DatabaseName = $TestDbName
    }
    Invoke-SQLFileOrQuery @parameters;
}elseif($DeploySource -eq "dacpac"){
    Log-Output('Deploying tSQLt from tSQLt DacPac...')

    $FriendlySQLServerVersion = Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection;
    $DacpacFileName = (Join-Path $SourcePath  ("tSQLtDacpacs/tSQLt."+$FriendlySQLServerVersion+".dacpac") | Resolve-Path);
    $SqlConnectionString = $SqlServerConnection.GetConnectionString($TestDbName,'DeployDacpac')
    & sqlpackage /a:Publish /tcs:"$SqlConnectionString" /sf:"$DacpacFileName"
    if($LASTEXITCODE -ne 0) {
        throw "error during deployment of dacpac " + $DacpacFileName;
    }
}

# Write-Warning('-->>------------>>--')
# Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection     
# Write-Warning('--<<------------<<--')
Log-Output('Run All Tests... Run Bootstrap Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Files = @(
        (Join-Path $TestsPath "BootStrapTest.sql" | Resolve-Path)
    )
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Install TestUtil.sql...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Files = @(
        (Join-Path $TestsPath "TestUtil.sql" | Resolve-Path)
    )
    DatabaseName = $TestDbName
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
    TestFilePath = (Join-Path $TestsPath "TestUtilTests.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_TestUtil.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... TestUtil_SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "TestUtilTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_TestUtil_SA.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt Tests...')
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        DatabaseName = $TestDbName
        TestFilePath = (Join-Path $TestsPath "AllTests.sql")
        OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`.xml")
    }
    Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "AllTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_SA.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt EXTERNAL_ACCESS_KEY_EXISTS Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "AllTests.EXTERNAL_ACCESS_KEY_EXISTS.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_EXTERNAL_ACCESS_KEY_EXISTS.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt EXTERNAL_ACCESS Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "AllTests.EXTERNAL_ACCESS.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_EXTERNAL_ACCESS.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... Set SummaryError O, Capture MultiRun Results...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Query = "EXEC tSQLt.SetSummaryError @SummaryError=1;EXEC tSQLt_testutil.CheckMultiRunResults @noError=1;EXEC tSQLt_testutil.StoreBuildLog @TableName='$LogTableName',@RunGroup='AllTests_$TestsResultFilePrefix';"
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;
