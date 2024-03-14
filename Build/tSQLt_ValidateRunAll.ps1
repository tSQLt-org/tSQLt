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

#----------------------------------------------------------------------------#
Log-Output('Run All Tests...')
#----------------------------------------------------------------------------#

if($DeploySource -eq "example"){
    & ./tSQLt_ValidateRunExampleTests.ps1
}else{    
    & ./tSQLt_ValidateRuntSQLtTests.ps1
}

Log-Output('Run All Tests... cleanup master...')
$parameters = @{
    SqlServerConnection = $SqlServerConnection
    HelperSQLPath = $HelperSQLPath
    Elevated = $true
    Files = @(
        (Join-Path $TestsPath "Drop(master.tSQLt_testutil).sql" | Resolve-Path)
    )
    DatabaseName = "tempdb"
}
Invoke-SQLFileOrQuery @parameters;
