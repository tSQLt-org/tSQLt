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

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"
Push-Location;
Set-Location $dir;

# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql", "tSQLtFacade.*.dacpac");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

Expand-Archive -Path "./output/tSQLtFacade.zip" -DestinationPath "./output";

Set-Location './output';

$SourceDatabaseName = $DatabaseName+"_src";
$AdditionalParameters = '-v FacadeSourceDb="'+$SourceDatabaseName+'" FacadeTargetDb="'+$DatabaseName+'_tgt"'
Exec-SqlFileOrQuery -ServerName $ServerName -Login $Login -SqlCmdPath $SqlCmdPath -FileName "ExecuteFacadeScript.sql" -AdditionalParameters $AdditionalParameters;

$QueryString = "DECLARE @FriendlyVersion NVARCHAR(128) = (SELECT FriendlyVersion FROM tSQLt.FriendlySQLServerVersion(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)))); PRINT @FriendlyVersion;";

$resultSet = Exec-SqlFileOrQuery -ServerName $ServerName -Login $Login -SqlCmdPath $SqlCmdPath -Query $QueryString -DatabaseName $SourceDatabaseName;
$resultSet;
throw "We still need to get the FriendlySQLServerVersion out of SQL Server (and the path for the output also maybe is wrong very currently)"

<# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
$AuthenticationString = $Login.trim() -replace '^((\s*([-]U\s+)(?<user>\w+)\s*)|(\s*([-]P\s+)(?<password>\S+)\s*))+$', 'User Id=${user};Password="${password}";'
$SqlConnectionString = "Data Source="+$ServerName+";"+$AuthenticationString+";Connect Timeout=60;Initial Catalog="+$DatabaseName+"_tgt";
& "$SqlPackagePath\sqlpackage.exe" /a:Extract /scs:"$SqlConnectionString" /tf:"output/tSQLtFacade.2018.dacpac" /p:DacApplicationName=tSQLtFacade.2019 /p:IgnoreExtendedProperties=true /p:DacMajorVersion=42 /p:DacMinorVersion=17 /p:ExtractUsageProperties=false

Pop-Location;
