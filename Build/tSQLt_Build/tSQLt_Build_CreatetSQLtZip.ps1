Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $CommitId
);

Push-Location -Path $PSScriptRoot
try{
    .(Join-Path $PSScriptRoot '../CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $scriptPath = $MyInvocation.MyCommand.Path;
    $invocationDir = $PSScriptRoot;
    $buildPath = Join-Path $invocationDir '../' | Resolve-Path;
    $tempPath = Join-Path $invocationDir '../temp/tSQLtBuild/' | Resolve-Path;
    $outputPath = Join-Path $invocationDir '../output/tSQLtBuild/' | Resolve-Path;
    $sourcePath = Join-Path $invocationDir '../../Source/' | Resolve-Path;
    $testUtilPath = Join-Path $invocationDir '../../TestUtil/' | Resolve-Path;

    Log-Output '<#--=======================================================================-->'
    Log-Output '<!--========                 Create CommitId.txt                  =========-->'
    Log-Output '<#--=======================================================================-->'

    Set-Content -Path (Join-Path $tempPath "CommitId.txt") -Value $CommitId;

    Log-Output '<#--=======================================================================-->'
    Log-Output '<!--========          Create GetFriendlySQLServerVersion.sql      =========-->'
    Log-Output '<#--=======================================================================-->'

    $templateContent = Get-Content -path (Join-Path $buildPath "SQL/GetFriendlySQLServerVersion.template.sql");
    $sqlFile1Content = Get-Content -path (Join-Path $sourcePath "tSQLt.FriendlySQLServerVersion.sfn.sql");
    $sqlFile2Content = Get-Content -path (Join-Path $sourcePath "tSQLt.Private_SplitSqlVersion.sfn.sql");

    $snip1Content = (Get-SnipContent $sqlFile1Content  "/*StartSnip*/" "/*EndSnip*/");
    $snip2Content = (Get-SnipContent $sqlFile2Content "/*StartSnip*/" "/*EndSnip*/");

    $FinalContent = (($templateContent.Replace("/*snip1content*/",$snip1Content).Replace("/*snip2content*/",$snip2Content)) -join [System.Environment]::NewLine);
    Set-Content -Path (Join-Path $tempPath 'GetFriendlySQLServerVersion.sql') -Value $FinalContent;

    Log-Output '<#--=======================================================================-->'
    Log-Output '<!--========          Create CreateBuildLog.sql                   =========-->'
    Log-Output '<#--=======================================================================-->'

    $testUtilContent = Get-Content -path (Join-Path $testUtilPath "tSQLt_testutil.class.sql");
    $CreateBuildLogRaw = (Get-SnipContent $testUtilContent "/*CreateBuildLogStart*/" "/*CreateBuildLogEnd*/");
    $CreateBuildLog = ($CreateBuildLogRaw -join [System.Environment]::NewLine).Replace("tSQLt_testutil.CreateBuildLog","#CreateBuildLog");
    $CreateBuildLog = ($CreateBuildLog + [System.Environment]::NewLine + "EXEC #CreateBuildLog @TableName='"+'$(BuildLogTableName)'+"';" + [System.Environment]::NewLine);
    Set-Content -Path (Join-Path $tempPath 'CreateBuildLog.sql') -Value ($CreateBuildLog);

    Log-Output '<#--=======================================================================-->'
    Log-Output '<!--========              Create/Copy output files                =========-->'
    Log-Output '<#--=======================================================================-->'

    $toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
    $compress = @{
        CompressionLevel = "Optimal"
        DestinationPath = (Join-Path $outputPath "tSQLtFiles.zip")
        }
    Get-ChildItem -Path (Join-Path $tempPath "*") -Include $toBeZipped | Compress-Archive @compress

    $toBeCopied = @("Version.txt", "tSQLt.class.sql", "CommitId.txt", "GetFriendlySQLServerVersion.sql", "CreateBuildLog.sql");
    Get-ChildItem -Path (Join-Path $tempPath "*")  -Include $toBeCopied | Copy-Item -Destination $outputPath;
    Copy-Item (Join-Path $tempPath "ReleaseNotes.txt") -Destination (Join-Path $outputPath "ReadMe.txt");

    
}
finally{
    Pop-Location
}