Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $LogTableName = ""
);
if([string]::IsNullOrWhiteSpace($LogTableName)){
    $LogTableName = "tempdb.dbo.[tSQLt-MultiRunLog(" + (New-Guid) + ")]";
}
# AllTests.Main.sql --> AllTests.sql

Function Invoke-SQLFileOrQuery
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $ServerName = $ServerName,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $Login = $Login,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tempdb',
        [Parameter(Mandatory=$true, ParameterSetName="Elevated")]
        [switch]$Elevated,
        [Parameter(Mandatory=$true, ParameterSetName="Caller")]
        [switch]$Caller,
        [Parameter(Mandatory=$false, ParameterSetName="Basic")]
        [switch]$Basic,
        [Parameter(Mandatory=$false)][string] $Query = $null,
        [Parameter(Mandatory=$false)][string[]] $Files = @(),
        [Parameter(Mandatory=$false)][hashtable] $AdditionalParameters = @{}
    );
    @{
        BuildLogTableName=$LogTableName
        DbName = "tempdb"
        ExecuteStatement=";"
        NewDbName = ("[This Shouldn't be here "+(New-Guid)+']')
    }.GetEnumerator()|ForEach-Object{if(!$AdditionalParameters.Contains($_.key)){$AdditionalParameters[$_.key]=$_.value;}}
    $AdditionalParametersString = "-v "+ (($AdditionalParameters.GetEnumerator()|ForEach-Object{$_.key +"='" + $_.value.replace("'","''") + "'"}) -Join " -v ")
    [string[]]$FileNames = @();
    if($Elevated){
        $FileNames += (Join-Path $TestsPath "temp_executeas_sa.sql")
    }elseif($Caller){
        $FileNames += (Join-Path $TestsPath "temp_executeas_caller.sql")
    }else{
        $FileNames += (Join-Path $TestsPath "temp_executeas.sql")
    }
    $ConcatenatedFileNames = @($FileNames)+@($Files);

    $parameters = @{
        ServerName = $ServerName
        Login = $Login
        FileNames = $ConcatenatedFileNames
        DatabaseName = $DatabaseName
        AdditionalParameters = $AdditionalParametersString
    }
    Exec-SqlFileOrQuery @parameters
}



$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $invocationDir 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $OutputPath = (Join-Path $invocationDir  "/output/Validate/");
    $TempPath = (Join-Path $invocationDir  "/temp/Validate/");
    $tSQLtPath = (Join-Path $TempPath  "/tSQLt/");
    $TestsPath = (Join-Path $TempPath  "/Tests/");
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
        $SQLVersion = Get-FriendlySQLServerVersion -ServerName $ServerName -Login $Login -Quiet

        $FixWidth = {param($m); return '|  '+$m.PadRight(70,' ')+'  |'}
        Log-Output('');
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output($FixWidth.invoke("Validating tSQLt Build"));
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output($FixWidth.invoke("tSQLt Version:      $tSQLtVersion"));
        Log-Output($FixWidth.invoke("tSQLt CommitId:     $tSQLtCommitId"));
        Log-Output($FixWidth.invoke("SQL Server:         $ServerName"));
        Log-Output($FixWidth.invoke("SQL Server Version: $SQLVersion"));
        Log-Output("+--------------------------------------------------------------------------+");
        Log-Output('');

    Log-Output('Building helper scripts...')
        $FixPath={param($l);$l|ForEach-Object{Join-Path $TestsPath $_ | Resolve-Path;}};
        $ConcatenateFiles = {param([string]$output, [string[]]$fileList)
            $Parameters = @{
                OutputFile = (Join-Path $TestsPath $output)
                InputPath = (& $FixPath $fileList)
            }
            & ./tSQLt_Build/ConcatenateFiles.ps1 @Parameters 
        };
        & $ConcatenateFiles "temp_executeas.sql" @(
            "ExecuteAs(tSQLt.Build).sql",
            "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        & $ConcatenateFiles "temp_executeas_sa.sql" @(
            "ExecuteAs(tSQLt.Build.SA).sql",
            "ChangeDbAndExecuteStatement(tSQLt.Build).sql"
        ) ;
        (Join-Path $TestsPath "ChangeDbAndExecuteStatement(tSQLt.Build).sql" | Resolve-Path)|Copy-Item -Destination (Join-Path $TestsPath "temp_executeas_caller.sql");
        & $ConcatenateFiles "temp_create_example.sql" @(
            "../tSQLt/Example.sql",
            "TestUtil.sql",
            "TestThatExamplesAreDeployed.sql"
        ) ;

    Log-Output('Creating Log Table...')
        $parameters = @{
            Elevated = $true
            Files = @(
                (Join-Path $TestsPath "CreateBuildLog.sql" | Resolve-Path)
            )
            DatabaseName = 'tempdb'
            AdditionalParameters = @{
                'BuildLogTableName' = $LogTableName
            }
        }
        Invoke-SQLFileOrQuery @parameters;
    
    Log-Output('Reset Validation Server...')
        $parameters = @{
            Caller = $true
            Files = @(
                (Join-Path $TestsPath "ResetValidationServer.sql" | Resolve-Path)
                (Join-Path $tSQLtPath "PrepareServer.sql" | Resolve-Path)
            )
            DatabaseName = 'tempdb'
        }
        Invoke-SQLFileOrQuery @parameters;
      
    Log-Output('Run All Tests...')
    Log-Output("Run All Tests... Create Database $DatabaseName ...")
        $parameters = @{
            Elevated = $true
            Files = @(
                (Join-Path $TestsPath "CreateBuildDb.sql" | Resolve-Path)
            )
            DatabaseName = "tempdb"
            AdditionalParameters = @{NewDbName = $DatabaseName}
        }
        Invoke-SQLFileOrQuery @parameters;

    Log-Output('Run All Tests... Install tSQLt...')
        $parameters = @{
            Files = @(
                (Join-Path $tSQLtPath "tSQLt.class.sql" | Resolve-Path)
            )
            AdditionalParameters = @{DbName = $DatabaseName}
        }
        Invoke-SQLFileOrQuery @parameters;

    Log-Output('Run All Tests... prepare master...')
        $parameters = @{
            Elevated = $true
            Files = @(
                (Join-Path $TestsPath "Drop(master.tSQLt_testutil).sql" | Resolve-Path)
                (Join-Path $TestsPath "Install(master.tSQLt_testutil).sql" | Resolve-Path)
                (Join-Path $TestsPath "Drop(tSQLtAssemblyKey)(Pre2017).sql" | Resolve-Path)
            )
        }
        Invoke-SQLFileOrQuery @parameters;

    Log-Output('Run All Tests... Run Bootstrap Tests...')
        $parameters = @{
            Files = @(
                (Join-Path $TestsPath "BootStrapTest.sql" | Resolve-Path)
            )
            AdditionalParameters = @{DbName = $DatabaseName}
        }
        Invoke-SQLFileOrQuery @parameters;


    <# Create the tSQLt.TestResults.zip in the public output path #>
    # $compress = @{
    #     CompressionLevel = "Optimal"
    #     DestinationPath = $PublicOutputPath + "/tSQLt.TestResults.zip"
    # }
    # Get-ChildItem -Path $PublicTempPath | Compress-Archive @compress

}
finally{
    Pop-Location
}
