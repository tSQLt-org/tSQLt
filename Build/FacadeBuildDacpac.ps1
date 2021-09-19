Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlPackagePath
);
<#
Technically this should be called by a matrixed job, so that dacpacs are built for all versions (we support, like not 2005, 2008)
Execute on a target server the Facade scripts

EXEC Facade.CreateAllFacadeObjects
#>

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/DacpacBuild/";
$TempPath = $dir + "/temp/DacpacBuild/";

<# Clean #>
Remove-DirectoryQuietly -Path $TempPath;
Remove-DirectoryQuietly -Path $OutputPath;

<# Init #>
$tempDir = New-Item -ItemType "directory" -Path $TempPath;
$outputDir = New-Item -ItemType "directory" -Path $OutputPath;

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();


Log-Output "FileLocation: $dir";
Push-Location;
Set-Location $dir;

Expand-Archive -Path "./output/tSQLtBuild/tSQLtFacade.zip" -DestinationPath $TempPath;

Set-Location $TempPath;

$SourceDatabaseName = $DatabaseName+"_src";
$TargetDatabaseName = $DatabaseName+"_tgt";
$AdditionalParameters = '-v FacadeSourceDb="'+$SourceDatabaseName+'" FacadeTargetDb="'+$DatabaseName+'_tgt"'

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -DatabaseName $SourceDatabaseName;
$FacadeDacpacFileName = "tSQLtFacade."+$FriendlySQLServerVersion+".dacpac";
$FacadeApplicationName = "tSQLtFacade."+$FriendlySQLServerVersion;
$FacadeConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -DatabaseName $TargetDatabaseName;

$tSQLtDacpacFileName = "tSQLt."+$FriendlySQLServerVersion+".dacpac";
$tSQLtApplicationName = "tSQLt."+$FriendlySQLServerVersion;
$tSQLtConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -DatabaseName $SourceDatabaseName;

Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames @("ResetValidationServer.sql","PrepareServer.sql");

Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames "ExecuteFacadeScript.sql" -AdditionalParameters $AdditionalParameters;

& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$FacadeConnectionString" /tf:"$FacadeDacpacFileName" /p:DacApplicationName="$FacadeApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeDacpacFileName;
}

& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$tSQLtConnectionString" /tf:"$tSQLtDacpacFileName" /p:DacApplicationName="$tSQLtApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $tSQLtDacpacFileName;
}

Copy-Item -Path $FacadeDacpacFileName -Destination $OutputPath;
Copy-Item -Path $tSQLtDacpacFileName -Destination $OutputPath;

Pop-Location;
