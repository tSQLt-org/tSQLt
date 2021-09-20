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
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlPackagePath,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LogTableName
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"

$TempPath = $dir + "/temp/Validate";
$FacadeFilesPath = $TempPath + "/FacadeDacpacs";
$TestResultsPath = $TempPath + "/TestResults/TestResults_Facade.xml";

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();

Expand-Archive -Path "./output/tSQLt/validation/tSQLtFacade.zip" -DestinationPath $FacadeFilesPath;

Push-Location;

$FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -DatabaseName $DatabaseName;
$FacadeFileName = $TempPath + "/tSQLt/FacadeDacpacs/tSQLtFacade."+$FriendlySQLServerVersion+".dacpac";

$DacpacDatabaseName = $DatabaseName+"_dacpac";
$AdditionalParameters = '-v NewDbName="'+$DacpacDatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "CreateBuildDb.sql" -DatabaseName 'tempdb' -AdditionalParameters $AdditionalParameters;

$SqlConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login $LoginTrimmed -DatabaseName $DacpacDatabaseName;
& "$SqlPackagePath/sqlpackage.exe" /a:Publish /tcs:"$SqlConnectionString" /sf:"$FacadeFileName"
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeFileName;
}

Set-Location $FacadeFilesPath;

$AdditionalParameters = '-v FacadeSourceDb="'+$DatabaseName+'_src" FacadeTargetDb="'+$DatabaseName+'_tgt" DacpacTargetDb="'+$DacpacDatabaseName+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "DeployFacadeTests.sql" -AdditionalParameters $AdditionalParameters;

Set-Location '../tSQLt.tests';

$SourceDatabaseName = $DatabaseName+"_src";
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames ($TempPath + "/tSQLt.tests/TestUtil.sql") -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -Query "EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -Query "EXEC tSQLt.RunAll;" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -Query "EXEC tSQLt_testutil.LogMultiRunResult 'DeployFacadeTests.sql';" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;
$AdditionalParameters = '-o "'+$TestResultsPath+'"';
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -FileNames "GetTestResults.sql" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login $LoginTrimmed -SqlCmdPath $SqlCmdPath -Query "EXEC tSQLt.SetSummaryError @SummaryError=1;EXEC tSQLt_testutil.CheckMultiRunResults @noError=1;EXEC tSQLt_testutil.StoreBuildLog @TableName='$LogTableName',@RunGroup='Facade';" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;

Pop-Location;

