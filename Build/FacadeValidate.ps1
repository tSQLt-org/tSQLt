<#
- validate that the dacpac is correct by installing tSQLt on one database; installing the dacpac on another database; get the list of names from sys.objects where the name is not Private%; assert that it is the same list
-- makesure that the database principal exists, [tSQLt.TestClasses] (maybe)
-- 
#>
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlPackagePath
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"

$TempPath = $dir + "/temp/Validate";
$FacadeFilesPath = $TempPath + "/Facade";
$TestResultsPath = $TempPath + "/TestResults/TestResults_Facade.xml";

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();

Expand-Archive -Path "./output/tSQLtBuild/tSQLtFacade.zip" -DestinationPath $FacadeFilesPath;

Push-Location;

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -DatabaseName $DatabaseName;
$FacadeFileName = $TempPath + "/tSQLt/Facade/tSQLtFacade."+$FriendlySQLServerVersion+".dacpac";

$DacpacDatabaseName = $DatabaseName+"_dacpac";
$AdditionalParameters = '-v NewDbName="'+$DacpacDatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "CreateBuildDb.sql" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;

$SqlConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login $LoginTrimmed -DatabaseName $DacpacDatabaseName;
& "$SqlPackagePath\sqlpackage.exe" /a:Publish /tcs:"$SqlConnectionString" /sf:"$FacadeFileName"
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeFileName;
}

Set-Location $FacadeFilesPath;

$AdditionalParameters = '-v FacadeSourceDb="'+$DatabaseName+'_src" FacadeTargetDb="'+$DatabaseName+'_tgt" DacpacTargetDb="'+$DacpacDatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "ExecuteFacadeTests.sql" -AdditionalParameters $AdditionalParameters;

Set-Location '../tSQLt.tests';

$AdditionalParameters = '-o "'+$TestResultsPath+'"';
$SourceDatabaseName = $DatabaseName+"_src";
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "GetTestResults.sql" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;


Pop-Location;
