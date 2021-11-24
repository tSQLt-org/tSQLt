<#
- validate that the dacpac is correct by installing tSQLt on one database; installing the dacpac on another database; get the list of names from sys.objects where the name is not Private%; assert that it is the same list
-- makesure that the database principal exists, [tSQLt.TestClasses] (maybe)
-- 
#>
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $RemoteDatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlPackagePath
);

$dir = $PSScriptRoot;

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"

$BuildPath = $dir+'/';
$ArtifactPath = $dir + "/output/tSQLt/";
$PublicArtifactPath = $ArtifactPath + "public/";
$TempPath = $dir + "/temp/Validate/";
$DeployDacpacFilesPath = $TempPath + "DeploytSQLtDacpacs/";
$DacpacsPath = $DeployDacpacFilesPath + "tSQLtDacpacs/";
Expand-Archive -Path ($PublicArtifactPath+"tSQLt.zip") -DestinationPath $DeployDacpacFilesPath;

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath;
$DacpacFileName = $DacpacsPath + "tSQLt."+$FriendlySQLServerVersion+".dacpac";

$AdditionalParameters = '-v NewDbName="'+$DatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames ($BuildPath+"CreateBuildDb.sql") -DatabaseName 'tempdb' -AdditionalParameters $AdditionalParameters;

$AdditionalParameters = '-v NewDbName="'+$RemoteDatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames ($BuildPath+"CreateBuildDb.sql") -DatabaseName 'tempdb' -AdditionalParameters $AdditionalParameters;

$SqlConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login $LoginTrimmed -DatabaseName $DatabaseName;
& "$SqlPackagePath/sqlpackage.exe" /a:Publish /tcs:"$SqlConnectionString" /sf:"$DacpacFileName"
if($LASTEXITCODE -ne 0) {
    throw "error during deployment of dacpac " + $DacpacFileName;
}

