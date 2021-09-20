Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $CommitId
);

$scriptPath = $MyInvocation.MyCommand.Path;
$invocationDir = Split-Path $scriptPath;
$buildPath = $invocationDir +'/';
$tempPath = $invocationDir + '/temp/tSQLtBuild/';
$outputPath = $invocationDir + '/output/tSQLtBuild/';
$sourcePath = $invocationDir + '/../Source/';

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

Write-Host "****************************************"
$outputOn = $false;
$snip1Content = ($sqlFile1Content | ForEach-Object {if($_ -eq "/*EndSnip*/"){$outputOn = $false};if($outputOn){$_};if($_ -eq "/*StartSnip*/"){$outputOn = $true};} )
Write-Host $snip1Content;
Write-Host "****************************************"
$outputOn = $false;
$snip2Content = ($sqlFile2Content | ForEach-Object {if($_ -eq "/*EndSnip*/"){$outputOn = $false};if($outputOn){$_};if($_ -eq "/*StartSnip*/"){$outputOn = $true};} )
Write-Host $snip2Content;
Write-Host "****************************************"

$FinalContent = $templateContent.Replace("/*snip1content*/",$snip1Content).Replace("/*snip2content*/",$snip2Content);
Set-Content -Path ($tempPath + 'GetFriendlySQLServerVersion.sql') -Value ($FinalContent -join [System.Environment]::NewLine);

<#--=======================================================================-->
<!--========              Create/Copy output files                =========-->
<!--=======================================================================-#>

$toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = ($outputPath + "tSQLtFiles.zip")
    }
Get-ChildItem -Path ($tempPath + "*") -Include $toBeZipped | Compress-Archive @compress

$toBeCopied = @("Version.txt", "tSQLt.class.sql", "CommitId.txt", "GetFriendlySQLServerVersion.sql");
Get-ChildItem -Path ($tempPath + "*")  -Include $toBeCopied | Copy-Item -Destination $outputPath;
Copy-Item ($tempPath + "ReleaseNotes.txt") -Destination ($outputPath + "ReadMe.txt");

