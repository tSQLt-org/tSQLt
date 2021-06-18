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
"GotHere";


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

"GotHere";
Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -FileName "ExecuteFacadeScript.sql" -AdditionalParameters $AdditionalParameters;
$QueryString = "DECLARE @FriendlyVersion NVARCHAR(128) = (SELECT FriendlyVersion FROM tSQLt.FriendlySQLServerVersion(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)))); PRINT @FriendlyVersion;";
"GotHere";

$resultSet = Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -Query $QueryString -DatabaseName $SourceDatabaseName;
Log-Output "Friendly SQL Server Version: $resultSet";
"GotHere";

<# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
$FacadeFileName = "tSQLtFacade."+$resultSet.Trim()+".dacpac";


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

$DacpacApplicationName = "tSQLtFacade."+$resultSet.Trim();

if ($LoginTrimmed -match '((.*[-]U)|(.*[-]P))+.*'){
    $AuthenticationString = $LoginTrimmed -replace '^((\s*([-]U\s+)(?<user>\w+)\s*)|(\s*([-]P\s+)(?<password>\S+)\s*))+$', 'User Id=${user};Password="${password}"'  
}
elseif ($LoginTrimmed -eq "-E"){
    $AuthenticationString = "Integrated Security=SSPI;";
}
else{
    throw $LoginTrimmed + " is not supported here."
}
$AuthenticationString;
$SqlConnectionString = "Data Source="+$resolvedServerName+";"+$AuthenticationString+";Connect Timeout=60;Initial Catalog="+$DatabaseName+"_tgt";
& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$SqlConnectionString" /tf:"$FacadeFileName" /p:DacApplicationName="$DacpacApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
if($LASTEXITCODE -ne 0) {
    throw "error during execution of dacpac " + $FacadeFileName;
}

Pop-Location;
