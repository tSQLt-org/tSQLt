Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlPackagePath
);
<#
Technically this should be called by a matrixed job, so that dacpacs are built for all versions (we support, like not 2005, 2008)
#>

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/DacpacBuild/";
$TempPath = $dir + "/temp/DacpacBuild/";

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();


Log-Output "FileLocation: $dir";
Push-Location;
Set-Location $TempPath;

Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames @("ResetValidationServer.sql","PrepareServer.sql");
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames ($dir+"/CreateBuildDb.sql") -Database "tempdb" -AdditionalParameters ('-v NewDbName="'+$DatabaseName+'"');
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames "tSQLt.class.sql" -Database "$DatabaseName";

$tSQLtDacpacFileName = "tSQLt."+$FriendlySQLServerVersion+".dacpac";
$tSQLtApplicationName = "tSQLt."+$FriendlySQLServerVersion;
$tSQLtConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -DatabaseName $DatabaseName;

& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$tSQLtConnectionString" /tf:"$tSQLtDacpacFileName" /p:DacApplicationName="$tSQLtApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $tSQLtDacpacFileName;
}

Copy-Item -Path $tSQLtDacpacFileName -Destination $OutputPath;

Pop-Location;
