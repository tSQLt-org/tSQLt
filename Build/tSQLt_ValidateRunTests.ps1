using module "./CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $HelperSQLPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $TestDbName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LogTableName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $TestsResultFilePrefix,    
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DeploySource,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SourcePath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $TestsPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ResultsPath
);



function Copy-SQLXmlToFile {
    # This has been tested for up to 100MB of test results! 
    # (Likely there is no limit, other than the 2GB of the XML data type.)
    param (
        [SqlServerConnection]$sqlServerConnection,
        [string]$DatabaseName,
        [string]$query,
        [string]$outputFile
    )

    Add-Type -AssemblyName System.Data

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($sqlServerConnection.GetConnectionString($DatabaseName,"Copy-SQLXmlToFile"))
        $connection.Open()

        $command = $connection.CreateCommand()
        $command.CommandText = $query

        $dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(tSQLt_Validate.ps1:Copy-SQLXmlToFile:ExecuteScalar[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
        $result = $command.ExecuteScalar()
        $dddafter = Get-Date;Write-Warning("------->>After<<-------(tSQLt_Validate.ps1:Copy-SQLXmlToFile:ExecuteScalar[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
        $dddafter-$dddbefore
        [System.IO.File]::WriteAllText($outputFile, $result)
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        $connection.Close()
    }
}

Function Invoke-Tests
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $HelperSQLPath,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
        [Parameter(Mandatory=$false)][switch]$Elevated,
        [Parameter(Mandatory=$true)][string] $TestSetName,
        [Parameter(Mandatory=$true)][string] $RunCommand,
        [Parameter(Mandatory=$true)][string] $OutputFile
    );
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        Elevated = $Elevated
        Query = $RunCommand
        DatabaseName = $DatabaseName
        PrintSqlOutput = $true
    }
    $dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(tSQLt_Validate.ps1:Invoke-Tests:Invoke-SQLFileOrQuery[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    $parameters;
    Invoke-SQLFileOrQuery @parameters;   
    $dddafter = Get-Date;Write-Warning("------->>After<<-------(tSQLt_Validate.ps1:Invoke-Tests:Invoke-SQLFileOrQuery[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    $dddafter-$dddbefore

    $dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(tSQLt_Validate.ps1:Invoke-Tests:Copy-SQLXmlToFile[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    Copy-SQLXmlToFile $SqlServerConnection $DatabaseName "EXEC [tSQLt].[XmlResultFormatter]" $OutputFile
    $dddafter = Get-Date;Write-Warning("------->>After<<-------(tSQLt_Validate.ps1:Invoke-Tests:Copy-SQLXmlToFile[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    $dddafter-$dddbefore

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        DatabaseName = $DatabaseName
        Query = "EXEC tSQLt_testutil.LogMultiRunResult '$TestSetName';"
    }
    $dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(tSQLt_Validate.ps1:Invoke-Tests:Invoke-SQLFileOrQuery[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    # $parameters;
    Invoke-SQLFileOrQuery @parameters;         
    $dddafter = Get-Date;Write-Warning("------->>After<<-------(tSQLt_Validate.ps1:Invoke-Tests:Invoke-SQLFileOrQuery[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
    $dddafter-$dddbefore

}
Function Invoke-TestsFromFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $HelperSQLPath,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
        [Parameter(Mandatory=$false)][switch]$Elevated,
        [Parameter(Mandatory=$true)][string] $TestFilePath,
        [Parameter(Mandatory=$true)][string] $OutputFile
    );

    $TestSetName = [System.IO.Path]::GetFileName($TestFilePath);

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        DatabaseName = $DatabaseName
        Query = "EXEC tSQLt.Reset;"
    }
    Invoke-SQLFileOrQuery @parameters;

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        Files = @($TestFilePath)
        DatabaseName = $DatabaseName
    }
    Invoke-SQLFileOrQuery @parameters;

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        DatabaseName = $DatabaseName
        Elevated = $Elevated
        RunCommand = "EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.RunNew;"
        OutputFile = $OutputFile
        TestSetName = $TestSetName
    }
    Invoke-Tests @parameters;

}








Log-Output('Reset Validation Server...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Caller = $true
    Files = @(
        (Join-Path $TestsPath "ResetValidationServer.sql" | Resolve-Path)
        (Join-Path $SourcePath "PrepareServer.sql" | Resolve-Path)
    )
    DatabaseName = 'tempdb'
}
Invoke-SQLFileOrQuery @parameters;

#----------------------------------------------------------------------------#
Log-Output('Run All Tests...')
#----------------------------------------------------------------------------#
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
    $DacpacFileName = (Join-Path $SourcePath  ("tSQLtDacPacs/tSQLt."+$FriendlySQLServerVersion+".dacpac") | Resolve-Path);
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
    HelperSQLPath = $HelperSQLPath
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
# Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... TestUtil_SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "TestUtilTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_TestUtil_SA.xml")
}
# Invoke-TestsFromFile @parameters;

# Log-Output('Run All Tests... tSQLt Tests...')
#     $parameters = @{
#         SqlServerConnection = $SqlServerConnection
#         DatabaseName = $TestDbName
#         TestFilePath = (Join-Path $TestsPath "AllTests.sql")
#         OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`.xml")
#     }
#     Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... tSQLt SA Tests...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    DatabaseName = $TestDbName
    Elevated = $true
    TestFilePath = (Join-Path $TestsPath "AllTests.SA.sql")
    OutputFile = (Join-Path $ResultsPath "TestResults_$TestsResultFilePrefix`_SA.xml")
}
# Invoke-TestsFromFile @parameters;

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
# Invoke-TestsFromFile @parameters;

Log-Output('Run All Tests... Set SummaryError O, Capture MultiRun Results...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Query = "EXEC tSQLt.SetSummaryError @SummaryError=1;EXEC tSQLt_testutil.CheckMultiRunResults @noError=1;EXEC tSQLt_testutil.StoreBuildLog @TableName='$LogTableName',@RunGroup='AllTests_$TestsResultFilePrefix';"
    DatabaseName = $TestDbName
}
Invoke-SQLFileOrQuery @parameters;

