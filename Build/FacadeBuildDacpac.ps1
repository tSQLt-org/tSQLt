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

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();


Log-Output "FileLocation: $dir";
Push-Location;
Set-Location $TempPath;

$SourceDatabaseName = $DatabaseName+"_src";
$TargetDatabaseName = $DatabaseName+"_tgt";
$AdditionalParameters = '-v FacadeSourceDb="'+$SourceDatabaseName+'" FacadeTargetDb="'+$DatabaseName+'_tgt"'

Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames @("ResetValidationServer.sql","PrepareServer.sql");
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileNames "ExecuteFacadeScript.sql" -AdditionalParameters $AdditionalParameters;

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath;
$FacadeDacpacFileName = "tSQLtFacade."+$FriendlySQLServerVersion+".dacpac";
$FacadeApplicationName = "tSQLtFacade."+$FriendlySQLServerVersion;
$FacadeConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -DatabaseName $TargetDatabaseName;

& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$FacadeConnectionString" /tf:"$FacadeDacpacFileName" /p:DacApplicationName="$FacadeApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeDacpacFileName;
}

Copy-Item -Path $FacadeDacpacFileName -Destination $OutputPath;

Pop-Location;
