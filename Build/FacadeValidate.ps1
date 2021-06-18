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

$ServerNameTrimmed = $ServerName.Trim();
$LoginTrimmed = $Login.Trim("'").Trim();

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"

# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

Expand-Archive -Path "./output/tSQLtFacade.zip" -DestinationPath "./output";

Push-Location;
Set-Location './output';

$AdditionalParameters = '-v FacadeSourceDb="'+$DatabaseName+'_src" FacadeTargetDb="'+$DatabaseName+'_tgt"'
Exec-SqlFileOrQuery -ServerName $ServerName -Login $Login -SqlCmdPath $SqlCmdPath -FileName "ExecuteFacadeTests.sql" -AdditionalParameters $AdditionalParameters;

Set-Location '..';
$SourceDatabaseName = $DatabaseName+"_src";
Exec-SqlFileOrQuery -ServerName $ServerName -Login $Login -SqlCmdPath $SqlCmdPath -FileName "GetTestResults.sql" -DatabaseName $SourceDatabaseName -AdditionalParameters '-o "output/TestResults_Facade.xml"';

$QueryString = "DECLARE @FriendlyVersion NVARCHAR(128) = (SELECT FriendlyVersion FROM tSQLt.FriendlySQLServerVersion(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)))); PRINT @FriendlyVersion;";
$resultSet = Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -Query $QueryString -DatabaseName $SourceDatabaseName;
Log-Output "Friendly SQL Server Version: $resultSet";

$FacadeFileName = "output/tSQLtFacade."+$resultSet.Trim()+".dacpac";
<# 
  ☹️
  This is so questionable, but it looks like sqlpackage cannot handle valid connection strings that use a valid server alias.
  The following snippet is meant to spelunk through the registry and extract the actual server from the alias.
  ☹️
 #>
 $resolvedServerName = $ServerNameTrimmed;
 $serverAlias = Get-Item -Path HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo
 if ($serverAlias.GetValueNames() -contains $ServerNameTrimmed) {
     $aliasValue = $serverAlias.GetValue($ServerNameTrimmed)
     if ($aliasValue -match "DBMSSOCN[,](.*)"){
         $resolvedServerName = $Matches[1];
     }
 }
 
<# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
if ($LoginTrimmed -match '((.*[-]U)|(.*[-]P))+.*'){
    $AuthenticationString = $LoginTrimmed -replace '^((\s*([-]U\s+)(?<user>\w+)\s*)|(\s*([-]P\s+)(?<password>\S+)\s*))+$', 'User Id=${user};Password="${password}"'  
}
elseif ($LoginTrimmed -eq "-E"){
    $AuthenticationString = "Integrated Security=SSPI;";
}
else{
    throw $LoginTrimmed + " is not supported here."
}

$SqlConnectionString = "Data Source="+$resolvedServerName+";"+$AuthenticationString+";Connect Timeout=60;Initial Catalog="+$DatabaseName+"_dacpac";
$SqlConnectionString;
& "$SqlPackagePath\sqlpackage.exe" /a:Publish /tcs:"$SqlConnectionString" /sf:"$FacadeFileName"
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeFileName;
}

Pop-Location;

throw "we still need to validate the dacpac (see line 2 and 3), so this should still fail, also -E doesn't work awesome"