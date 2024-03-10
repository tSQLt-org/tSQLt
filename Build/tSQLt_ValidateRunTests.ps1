using module "./CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $TestDbName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LogTableName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DeploySource,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SourcePath
);


Log-Output('Reset Validation Server...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    Caller = $true
    Files = @(
        (Join-Path $TestsPath "ResetValidationServer.sql" | Resolve-Path)
        (Join-Path $tSQLtPath "PrepareServer.sql" | Resolve-Path)
    )
    DatabaseName = 'tempdb'
}
Invoke-SQLFileOrQuery @parameters;

$RunAllTestsResultFilePrefix = 'tSQLt'    
#----------------------------------------------------------------------------#
Log-Output('Run All Tests...')
#----------------------------------------------------------------------------#
Log-Output("Run All Tests... Create Database $TestDbName ...")
$parameters = @{
    SqlServerConnection = $SqlServerConnection
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
        Files = @(
            (Join-Path $SourcePath "tSQLt.class.sql" | Resolve-Path)
        )
        DatabaseName = $TestDbName
    }
    Invoke-SQLFileOrQuery @parameters;
}elseif($DeploySource -eq "dacpac"){
    Log-Output('Deploying tSQLt from tSQLt DacPac...')

    $FriendlySQLServerVersion = Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection;
    $DacpacFileName = (Join-Path $SourcePath  ("tSQLt."+$FriendlySQLServerVersion+".dacpac") | Resolve-Path);
    $SqlConnectionString = $SqlServerConnection.GetConnectionString($TestDbName,'DeployDacpac')
    & sqlpackage /a:Publish /tcs:"$SqlConnectionString" /sf:"$DacpacFileName"
    if($LASTEXITCODE -ne 0) {
        throw "error during deployment of dacpac " + $DacpacFileName;
    }
}

# Write-Warning('-->>------------>>--')
# Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection     
# Write-Warning('--<<------------<<--')
Log-Output('Run All Tests... prepare master...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    Elevated = $true
    Files = @(
        (Join-Path $TestsPath "Drop(master.tSQLt_testutil).sql" | Resolve-Path)
        (Join-Path $TestsPath "Install(master.tSQLt_testutil).sql" | Resolve-Path)
        (Join-Path $TestsPath "Drop(tSQLtAssemblyKey)(Pre2017).sql" | Resolve-Path)
    )
    DatabaseName = "tempdb"
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Run Bootstrap Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    Files = @(
        (Join-Path $TestsPath "BootStrapTest.sql" | Resolve-Path)
    )
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Install TestUtil.sql...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    Files = @(
        (Join-Path $TestsPath "TestUtil.sql" | Resolve-Path)
    )
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;

Log-Output('Run All Tests... Set SummaryError Off, PrepMultiRun...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    Query = "EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;"
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;


Log-Output('Run All Tests... TestUtil Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    DatabaseName = $TestDbName
    TestFilePath = (Join-Path $TestsPath "TestUtilTests.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_TestUtil.xml")
}
Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... TestUtil_SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "TestUtilTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_TestUtil_SA.xml")
}
Invoke-TestsFromFile @parameters;

# Log-Output('Run All Tests... tSQLt Tests...')
#     $parameters = @{
#         SqlServerConnection = $SqlServerConnection
#         DatabaseName = $TestDbName
#         TestFilePath = (Join-Path $TestsPath "AllTests.sql")
#         OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`.xml")
#     }
#     Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "AllTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_SA.xml")
}
Invoke-TestsFromFile @parameters;