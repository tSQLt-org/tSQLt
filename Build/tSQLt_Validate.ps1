using module "./CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $MainTestDb,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DacpacTestDb,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ExampleTestDb,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $LogTableName = ""
);


$validateStartTime = Get-Date;

$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    if([string]::IsNullOrWhiteSpace($LogTableName)){
        $LogTableName = "tempdb.dbo.[tSQLt-MultiRunLog(" + (New-Guid) + ")]";
    }
    
    $OutputPath = (Join-Path $invocationDir  "/output/Validate/");
    $TempPath = (Join-Path $invocationDir  "/temp/Validate/");
    $tSQLtPath = (Join-Path $TempPath  "/tSQLt/");
    $TestsPath = (Join-Path $TempPath  "/Tests/");
    $HelperSQLPath = (Join-Path $TempPath  "/Tests/");
    $ResultsPath = (Join-Path $TempPath  "/Results/");

    $tSQLtZipPath = (Join-Path $invocationDir "/output/tSQLt/public/tSQLt.zip" |Resolve-Path);
    $tSQLtTestsPath = (Join-Path $invocationDir "/output/tSQLt/validation" |Resolve-Path);

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;

    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $__ = New-Item -ItemType "directory" -Path $tSQLtPath;
    $__ = New-Item -ItemType "directory" -Path $TestsPath;
    $__ = New-Item -ItemType "directory" -Path $ResultsPath;
    $__ = New-Item -ItemType "directory" -Path $OutputPath;

    <# Copy files to temp path #>
    Expand-Archive -Path ($tSQLtZipPath) -DestinationPath $tSQLtPath;
    Expand-Archive -Path (Join-Path $tSQLtTestsPath "tSQLt.tests.zip" | Resolve-Path) -DestinationPath $TestsPath;
    @(
        'CreateBuildLog.sql'
        'GetFriendlySQLServerVersion.sql'
        'Version.txt'
        'CommitId.txt'
    )|ForEach-Object{(Join-Path $tSQLtTestsPath $_ | Resolve-Path)|Copy-Item -Destination $TestsPath}

    Log-Output('Initialization...')
        $tSQLtVersion = (Get-Content -path (Join-Path $TestsPath 'Version.txt' | Resolve-Path))
        $tSQLtCommitId = (Get-Content -path (Join-Path $TestsPath 'CommitId.txt' | Resolve-Path))
        $SQLVersion = Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection -Quiet

        $FixWidth = {param($m); return '|  '+$m.PadRight(70,' ')+'  |'}
        Log-Output('');
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output($FixWidth.invoke("Validating tSQLt Build"));
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output($FixWidth.invoke("tSQLt Version:      $tSQLtVersion"));
        Log-Output($FixWidth.invoke("tSQLt CommitId:     $tSQLtCommitId"));
        Log-Output($FixWidth.invoke("SQL Server:         $ServerName"));
        Log-Output($FixWidth.invoke("SQL Server Version: $SQLVersion"));
        Log-Output($FixWidth.invoke("Log Table Name:     $LogTableName"));
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output($FixWidth.invoke("Log Table Name:     $LogTableName"));
        Log-Output('');

    Log-Output('Building helper scripts...')
        $FixPath={param($l);$l|ForEach-Object{Write-Warning($_);  Join-Path $TestsPath $_ | Resolve-Path;}};
        $ConcatenateFiles = {param([string]$output, [string[]]$fileList)
            $Parameters = @{
                OutputFile = (Join-Path $TestsPath $output)
                InputPath = [string[]](& $FixPath $fileList)
            }
            & ./tSQLt_Build/ConcatenateFiles.ps1 @Parameters 
        };
        & $ConcatenateFiles "temp_executeas.sql" @(
            "ExecuteAs(tSQLt.Build).sql"
            # "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        & $ConcatenateFiles "temp_executeas_sa.sql" @(
            "ExecuteAs(tSQLt.Build.SA).sql"
            # "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        & $ConcatenateFiles "temp_executeas_caller.sql" @(
            # "ExecuteAs(tSQLt.Build.SA).sql"
            # "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        & $ConcatenateFiles "temp_executeas_cleanup.sql" @(
            "ExecuteAsCleanup.sql"
            # "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        & $ConcatenateFiles "temp_create_example.sql" @(
            "../tSQLt/Example.sql",
            "TestUtil.sql",
            "Add(tSQLt.Built)ToExampleDB.sql",
            "UseTempDb.sql"
        ) ;

    Log-Output("Creating Log Table $LogTableName ...")
        $parameters = @{
            SqlServerConnection = $SqlServerConnection
            HelperSQLPath = $HelperSQLPath
            Caller = $true
            Files = @(
                (Join-Path $TestsPath "CreateBuildLog.sql" | Resolve-Path)
            )
            DatabaseName = 'tempdb'
            AdditionalParameters = @{
                'BuildLogTableName' = $LogTableName
            }
        }
        Invoke-SQLFileOrQuery @parameters;
    
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        TestDbName = $MainTestDb
        LogTableName = $LogTableName
        TestsResultFilePrefix = 'tSQLt'
        DeploySource = 'class'
        SourcePath = $tSQLtPath
        TestsPath = $TestsPath
        ResultsPath = $ResultsPath
    }
    & ./tSQLt_ValidateRunAll.ps1 @parameters
    
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        TestDbName = $DacpacTestDb
        LogTableName = $LogTableName
        TestsResultFilePrefix = 'tSQLtDacPac'
        DeploySource = 'dacpac'
        SourcePath = $tSQLtPath
        TestsPath = $TestsPath
        ResultsPath = $ResultsPath
    }
    & ./tSQLt_ValidateRunAll.ps1 @parameters

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        TestDbName = '$null'
        LogTableName = $LogTableName
        TestsResultFilePrefix = '$null'
        DeploySource = 'example'
        SourcePath = $tSQLtPath
        TestsPath = $TestsPath
        ResultsPath = $ResultsPath
    }
    & ./tSQLt_ValidateRunAll.ps1 @parameters

    Log-Output('Create tSQLt.TestResults.zip ...')
    $compress = @{
        CompressionLevel = "Optimal"
        DestinationPath = $OutputPath + "/tSQLt.TestResults.zip"
    }
    Get-ChildItem -Path $ResultsPath | Compress-Archive @compress

    Log-Output('Summary of all tests...')
    Write-Warning("+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+");
    Write-Warning("|+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+|");
    Write-Warning("||                                                                           ||");
    Write-Warning("||                          Build Test Result Summary                        ||");
    Write-Warning("||                                                                           ||");
    Write-Warning("|+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+|");
    Write-Warning("+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+");    
    Write-Warning("");
    Write-Warning("Executed on SQL Server Version $SQLVersion");
    Write-Warning("");
      $parameters = @{
        SqlServerConnection = $SqlServerConnection
        HelperSQLPath = $HelperSQLPath
        Elevated = $true
        Query = "SET NOCOUNT ON;EXEC tSQLt_testutil.CheckBuildLog @TableName='$LogTableName';"
        DatabaseName = $MainTestDb
        PrintSqlOutput = $true
    }
    Invoke-SQLFileOrQuery @parameters;
    

    Log-Output('Confirm All Tests executed ...')
    $ExpectedTestResultFiles = (
        'TestResults_Example.xml',
        'TestResults_tSQLt.xml',
        'TestResults_tSQLt_external_access_key_exists.xml',
        'TestResults_tSQLt_external_access.xml',
        'TestResults_tSQLt_sa.xml',
        'TestResults_tSQLt_TestUtil.xml',
        'TestResults_tSQLt_TestUtil_SA.xml',
        'TestResults_tSQLtDacPac.xml',
        'TestResults_tSQLtDacPac_external_access_key_exists.xml',
        'TestResults_tSQLtDacPac_external_access.xml',
        'TestResults_tSQLtDacPac_sa.xml',
        'TestResults_tSQLtDacPac_TestUtil.xml',
        'TestResults_tSQLtDacPac_TestUtil_SA.xml'
    )
    $ActualTestResultFiles = (Get-ChildItem -Path $ResultsPath -Include "TestResults*.xml" -Recurse)|%{$_.name};
    $missingFiles = ($ExpectedTestResultFiles|Where-Object{$ActualTestResultFiles -NotContains $_})
    $superfluousFiles = ($ActualTestResultFiles|Where-Object{$ExpectedTestResultFiles -NotContains $_})
    $matchingFiles = ($ActualTestResultFiles|Where-Object{$ExpectedTestResultFiles -Contains $_})
    Log-Output("+------------------------------------------------");
    Log-Output("| Expected Test Result Files:");
    $matchingFiles|%{Log-Output("|  - $_");}
    Log-Output("+------------------------------------------------");
    if($missingFiles.length -gt 0){
        Log-Output("| Missing Test Result Files:");
        $missingFiles|%{Log-Output("|  - $_");}
    }else{
        Log-Output("| No Missing Test Result Files");
    }
    Log-Output("+------------------------------------------------");
    if($superfluousFiles.length -gt 0){
        Log-Output("| Unexpected Test Result Files:")
        $superfluousFiles|%{Log-Output("|  - $_");}
    }else{
        Log-Output("| No Unexpected Test Result Files");
    }
    Log-Output("+------------------------------------------------");
    if($missingFiles.Length + $superfluousFiles.Length -gt 0){
        Write-Error("Missing or Unexpected Test Result Files!")
    }
}
finally{
    Pop-Location
    $validateEndTime = Get-Date;
    Log-Output("------------------------------------")
    Log-Output("Total Duration: $($validateEndTime-$validateStartTime)")
    Log-Output("------------------------------------")
}

