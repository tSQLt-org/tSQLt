Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $CommitId
);

$scriptPath = $MyInvocation.MyCommand.Path;
$invocationDir = Split-Path $scriptPath;
$buildPath = $invocationDir +'/';
$tempPath = $invocationDir + '/temp/tSQLtBuild/';
$outputPath = $invocationDir + '/output/tSQLtBuild/';
$sourcePath = $invocationDir + '/../Source/';
$testUtilPath = $invocationDir + '/../TestUtil/';

.($buildPath+"CommonFunctionsAndMethods.ps1");

<#--=======================================================================-->
<!--========          Create CommitId.txt                         =========-->
<!--=======================================================================-#>

Set-Content -Path "temp/tSQLtBuild/CommitId.txt" -Value $CommitId;

<#--=======================================================================-->
<!--========          Create GetFriendlySQLServerVersion.sql      =========-->
<!--=======================================================================-#>

$templateContent = Get-Content -path ($buildPath + "GetFriendlySQLServerVersion.template.sql");
$sqlFile1Content = Get-Content -path ($sourcePath + "tSQLt.FriendlySQLServerVersion.sfn.sql");
$sqlFile2Content = Get-Content -path ($sourcePath + "tSQLt.Private_SplitSqlVersion.sfn.sql");

$snip1Content = (Get-SnipContent $sqlFile1Content  "/*StartSnip*/" "/*EndSnip*/");
$snip2Content = (Get-SnipContent $sqlFile2Content "/*StartSnip*/" "/*EndSnip*/");

$FinalContent = (($templateContent.Replace("/*snip1content*/",$snip1Content).Replace("/*snip2content*/",$snip2Content)) -join [System.Environment]::NewLine);
Set-Content -Path ($tempPath + 'GetFriendlySQLServerVersion.sql') -Value $FinalContent;

Write-Host "****************************************************"
$testUtilContent = Get-Content -path ($testUtilPath + "tSQLt_testutil.class.sql");
$CreateBuildLogRaw = (Get-SnipContent $testUtilContent "/*CreateBuildLogStart*/" "/*CreateBuildLogEnd*/");
$CreateBuildLog = ($CreateBuildLogRaw -join [System.Environment]::NewLine).Replace("tSQLt_testutil.CreateBuildLog","#CreateBuildLog");
$CreateBuildLog = ($CreateBuildLog + [System.Environment]::NewLine + "EXEC #CreateBuildLog @TableName='"+'$(BuildLogTableName)'+"';" + [System.Environment]::NewLine);
Set-Content -Path ($tempPath + 'CreateBuildLog.sql') -Value ($CreateBuildLog);
Write-Host "****************************************************"
<#--=======================================================================-->
<!--========              Create/Copy output files                =========-->
<!--=======================================================================-#>

$toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = ($outputPath + "tSQLtFiles.zip")
    }
Get-ChildItem -Path ($tempPath + "*") -Include $toBeZipped | Compress-Archive @compress

$toBeCopied = @("Version.txt", "tSQLt.class.sql", "CommitId.txt", "GetFriendlySQLServerVersion.sql", "CreateBuildLog.sql");
Get-ChildItem -Path ($tempPath + "*")  -Include $toBeCopied | Copy-Item -Destination $outputPath;
Copy-Item ($tempPath + "ReleaseNotes.txt") -Destination ($outputPath + "ReadMe.txt");

