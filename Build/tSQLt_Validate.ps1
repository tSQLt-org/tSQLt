using module "./CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][string] $UserName,
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][securestring] $Password,
    [Parameter(Mandatory=$true, ParameterSetName = 'TrustedCon')][ValidateNotNullOrEmpty()][switch] $TrustedConnection,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $LogTableName = ""
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
Function Invoke-SQLFileOrQuery
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlServerConnection,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tempdb',
        [Parameter(Mandatory=$true, ParameterSetName="Elevated")]
        [switch]$Elevated,
        [Parameter(Mandatory=$true, ParameterSetName="Caller")]
        [switch]$Caller,
        [Parameter(Mandatory=$false, ParameterSetName="Basic")]
        [switch]$Basic,
        [Parameter(Mandatory=$false)][string] $OutputFile = $null,
        [Parameter(Mandatory=$false)][string] $Query = "",
        [Parameter(Mandatory=$false)][string[]] $Files = @(),
        [Parameter(Mandatory=$false)][hashtable] $AdditionalParameters = @{}
    );
    $tempFile = $null;

    # Write-Warning("------->>NOTE<<-------(tSQLt_Validate.ps1:Invoke-SQLFileOrQuery:Adding Timestamps to Query")
    # $Query = 'PRINT CONVERT(VARCHAR(MAX),SYSUTCDATETIME(),127);'+$Query+'PRINT CONVERT(VARCHAR(MAX),SYSUTCDATETIME(),127);'

    try{
        @{
            BuildLogTableName=$LogTableName
            DbName = "tempdb"
            ExecuteStatement=";"
            NewDbName = ("[This Shouldn't be here "+(New-Guid)+']')
        }.GetEnumerator()|ForEach-Object{if(!$AdditionalParameters.Contains($_.key)){$AdditionalParameters[$_.key]=$_.value;}}

        [string[]]$FileNames = @();
        if($Elevated){
            $FileNames += (Join-Path $TestsPath "temp_executeas_sa.sql"|Resolve-Path)
        }elseif($Caller){
            $FileNames += (Join-Path $TestsPath "temp_executeas_caller.sql"|Resolve-Path)
        }else{
            $FileNames += (Join-Path $TestsPath "temp_executeas.sql"|Resolve-Path)
        }
        if (![string]::IsNullOrWhiteSpace($Query)){            
            $FileNames += Get-TempFileForQuery($Query)
        }
        $FullFileNameSet = @($FileNames)+@($Files);

        $parameters = @{
            ServerName = $ServerName
            UserName = $UserName
            Password = $Password
            TrustedConnection = $TrustedConnection
            FileNames = $FullFileNameSet
            DatabaseName = $DatabaseName
            AdditionalParameters = $AdditionalParametersString
        }
$dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(tSQLt_Validate.ps1:Invoke-SQLFileOrQuery:Exec-SqlFile[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
# $parameters
        Exec-SqlFile @parameters
$dddafter = Get-Date;Write-Warning("------->>After<<-------(tSQLt_Validate.ps1:Invoke-SQLFileOrQuery:Exec-SqlFile[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
$dddafter-$dddbefore

    }
    catch{
        throw
    }
    finally{
        if($null -ne $tempFile){
            Remove-Item -Path $tempFile.FullName -ErrorAction Ignore
        }
    }
}

Function Invoke-Tests
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlServerConnection,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
        [Parameter(Mandatory=$false)][switch]$Elevated,
        [Parameter(Mandatory=$true)][string] $TestSetName,
        [Parameter(Mandatory=$true)][string] $RunCommand,
        [Parameter(Mandatory=$true)][string] $OutputFile
    );
    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        Elevated = $Elevated
        Query = $RunCommand
        DatabaseName = $DatabaseName
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
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlConnectionString] $SqlConnectionString,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
        [Parameter(Mandatory=$false)][switch]$Elevated,
        [Parameter(Mandatory=$true)][string] $TestFilePath,
        [Parameter(Mandatory=$true)][string] $OutputFile
    );

    $TestSetName = [System.IO.Path]::GetFileName($TestFilePath);

    $parameters = @{
        ServerName = $ServerName
        UserName = $UserName
        Password = $Password
        TrustedConnection = $TrustedConnection
        DatabaseName = $DatabaseName
        Query = "EXEC tSQLt.Reset;"
    }
    Invoke-SQLFileOrQuery @parameters;

    $parameters = @{
        ServerName = $ServerName
        UserName = $UserName
        Password = $Password
        TrustedConnection = $TrustedConnection
        Files = @($TestFilePath)
        DatabaseName = $DatabaseName
    }
    Invoke-SQLFileOrQuery @parameters;

    $parameters = @{
        ServerName = $ServerName
        UserName = $UserName
        Password = $Password
        TrustedConnection = $TrustedConnection
        DatabaseName = $DatabaseName
        Elevated = $Elevated
        RunCommand = "EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.RunNew;"
        OutputFile = $OutputFile
        TestSetName = $TestSetName
    }
    Invoke-Tests @parameters;

}


$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    if([string]::IsNullOrWhiteSpace($LogTableName)){
        $LogTableName = "tempdb.dbo.[tSQLt-MultiRunLog(" + (New-Guid) + ")]";
    }
    if($TrustedConnection){
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,"tSQLt_Validate");
    }else{
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,$UserName,$Password,"tSQLt_Validate");
    }
    
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
        (Join-Path $TestsPath "ChangeDbAndExecuteStatement(tSQLt.Build).sql" | Resolve-Path)|Copy-Item -Destination (Join-Path $TestsPath "temp_executeas_caller.sql");

        & $ConcatenateFiles "temp_create_example.sql" @(
            "../tSQLt/Example.sql",
            "TestUtil.sql",
            "TestThatExamplesAreDeployed.sql"
        ) ;

    Log-Output('Creating Log Table...')
        $parameters = @{
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
    
    # Log-Output('Reset Validation Server...')
    #     $parameters = @{
    #         Caller = $true
    #         Files = @(
    #             (Join-Path $TestsPath "ResetValidationServer.sql" | Resolve-Path)
    #             (Join-Path $tSQLtPath "PrepareServer.sql" | Resolve-Path)
    #         )
    #         DatabaseName = 'tempdb'
    #     }
    #     Invoke-SQLFileOrQuery @parameters;
    
    # $RunAllTestsResultFilePrefix = 'tSQLt'    
    # #----------------------------------------------------------------------------#
    # Log-Output('Run All Tests...')
    # #----------------------------------------------------------------------------#
    # Log-Output("Run All Tests... Create Database $DatabaseName ...")
    #     $parameters = @{
    #         Elevated = $true
    #         Files = @(
    #             (Join-Path $TestsPath "CreateBuildDb.sql" | Resolve-Path)
    #         )
    #         DatabaseName = "tempdb"
    #         AdditionalParameters = @{NewDbName = $DatabaseName}
    #     }
    #     Invoke-SQLFileOrQuery @parameters;

    # Log-Output('Run All Tests... Install tSQLt...')
    #     $parameters = @{
    #         Files = @(
    #             (Join-Path $tSQLtPath "tSQLt.class.sql" | Resolve-Path)
    #         )
    #         DatabaseName = $DatabaseName
    #     }
    #     Invoke-SQLFileOrQuery @parameters;

    # Log-Output('Run All Tests... prepare master...')
    #     $parameters = @{
    #         Elevated = $true
    #         Files = @(
    #             (Join-Path $TestsPath "Drop(master.tSQLt_testutil).sql" | Resolve-Path)
    #             (Join-Path $TestsPath "Install(master.tSQLt_testutil).sql" | Resolve-Path)
    #             (Join-Path $TestsPath "Drop(tSQLtAssemblyKey)(Pre2017).sql" | Resolve-Path)
    #         )
    #     }
    #     Invoke-SQLFileOrQuery @parameters;

    # Log-Output('Run All Tests... Run Bootstrap Tests...')
    #     $parameters = @{
    #         Files = @(
    #             (Join-Path $TestsPath "BootStrapTest.sql" | Resolve-Path)
    #         )
    #         DatabaseName = $DatabaseName
    #     }
    #     Invoke-SQLFileOrQuery @parameters;

    # Log-Output('Run All Tests... Install TestUtil.sql...')
    #     $parameters = @{
    #         Files = @(
    #             (Join-Path $TestsPath "TestUtil.sql" | Resolve-Path)
    #         )
    #         DatabaseName = $DatabaseName
    #     }
    #     Invoke-SQLFileOrQuery @parameters;

    # Log-Output('Run All Tests... Set SummaryError Off, PrepMultiRun...')
    #     $parameters = @{
    #         Query = "EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;"
    #         DatabaseName = $DatabaseName
    #     }
    #     Invoke-SQLFileOrQuery @parameters;


    # Log-Output('Run All Tests... TestUtil Tests...')
    #     $parameters = @{
    #         TestFilePath = (Join-Path $TestsPath "TestUtilTests.sql")
    #         OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_TestUtil.xml")
    #     }
    #     Invoke-TestsFromFile @parameters;
    
    # Log-Output('Run All Tests... TestUtil_SA Tests...')
    #     $parameters = @{
    #         Elevated = $true
    #         TestFilePath = (Join-Path $TestsPath "TestUtilTests.SA.sql")
    #         OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_TestUtil_SA.xml")
    #     }
    #     Invoke-TestsFromFile @parameters;
    
    # Log-Output('Run All Tests... tSQLt Tests...')
    #     $parameters = @{
    #         TestFilePath = (Join-Path $TestsPath "AllTests.sql")
    #         OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`.xml")
    #     }
    #     Invoke-TestsFromFile @parameters;
    
    # Log-Output('Run All Tests... tSQLt SA Tests...')
    #     $parameters = @{
    #         Elevated = $true
    #         TestFilePath = (Join-Path $TestsPath "AllTests.SA.sql")
    #         OutputFile = (Join-Path $ResultsPath "TestResults_$RunAllTestsResultFilePrefix`_SA.xml")
    #     }
    #     Invoke-TestsFromFile @parameters;
    

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

