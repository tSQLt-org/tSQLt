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

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

Log-Output "FileLocation: $dir";
Push-Location;
Set-Location $dir;

# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql", "tSQLtFacade.*.dacpac");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

Expand-Archive -Path "./output/tSQLtFacade.zip" -DestinationPath "./output";

Set-Location './output';

$SourceDatabaseName = $DatabaseName+"_src";
$AdditionalParameters = '-v FacadeSourceDb="'+$SourceDatabaseName+'" FacadeTargetDb="'+$DatabaseName+'_tgt"'

Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileName "ExecuteFacadeScript.sql" -AdditionalParameters $AdditionalParameters;

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -DatabaseName $SourceDatabaseName;
$FacadeFileName = "tSQLtFacade."+$FriendlySQLServerVersion+".dacpac";
$DacpacApplicationName = "tSQLtFacade."+$FriendlySQLServerVersion;
$TargetDatabaseName = $DatabaseName+"_tgt";
$SqlConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login $LoginTrimmed -DatabaseName $TargetDatabaseName;

& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$SqlConnectionString" /tf:"$FacadeFileName" /p:DacApplicationName="$DacpacApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeFileName;
}

Pop-Location;
