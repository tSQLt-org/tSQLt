Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath
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

# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

Expand-Archive -Path "./output/tSQLtFacade.zip" -DestinationPath "./output";

Push-Location;
Set-Location './output';

$AdditionalParameters = '-v FacadeSourceDb="'+$DatabaseName+'_src" FacadeTargetDb="'+$DatabaseName+'_tgt"'
Exec-SqlFile -ServerName $ServerName -Login $Login -SqlCmdPath $SqlCmdPath -FileName "ExecuteFacadeScript.sql" -DatabaseName $SourceDatabaseName -AdditionalParameters $AdditionalParameters;

Pop-Location;
<# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
$SqlConnectionString = "Data Source="+$ServerName+";"+$Login+";Connect Timeout=60;Initial Catalog="+$DatabaseName+"_tgt";
& $env:SQLPACKAGE_HOME\sqlpackage.exe /a:Extract /scs:"$SqlConnectionString" /tf:tSQLtFacade.2019.dacpac /p:DacApplicationName=tSQLtFacade.2019 /p:IgnoreExtendedProperties=true /p:DacMajorVersion=42 /p:DacMinorVersion=17 /p:ExtractUsageProperties=false

throw "This is so weird, and it shouldn't be running scripts and nothing works. :("