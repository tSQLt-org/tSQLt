<# USAGE: ./CreateSQLContainer.ps1 -Location "East US 2" -ResourceGroupName "myTestResourceGroup" -SQLVersionEdition "2022L" -SQLPwd "aoeihag;ladjfalkj46" -BuildId "001" #>
using module "../../Build/CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Location,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ResourceGroupName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLVersionEdition,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPwd,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][int] $SQLCpu = 4,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][int] $SQLMemory = 8
);

$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir


$SQLPort = 1433;
$SQLUserName = 'SA';

$dir = $invocationDir;
$projectDir = Split-Path (Split-Path $dir);

Log-Output "FileLocation: ", $dir;
Log-Output "Project Location: ", $projectDir;


Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "<->                                             <->";
Log-Output "<->                  START 1                    <->";
Log-Output "<->                                             <->";
Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Parameters:";
Log-Output "ResourceGroupName:", $ResourceGroupName;
Log-Output "Location:", $Location;
Log-Output "BuildId:", $BuildId;
Log-Output "SQLVersionEdition:", $SQLVersionEdition;
Log-Output "SQLPort:", $SQLPort;
Log-Output "<-> END 1 <-><-><-><-><-><-><-><-><-><-><-><-><->";

<# FYI Usage: $SQLVersionEditionHash.$SQLVersionEdition.offer = "SQL2016SP2-WS2016" #>
$SQLVersionEditionHash = @{
    "2017L"=@{"sqlversion"="2017";"image"="mcr.microsoft.com/mssql/server:2017-latest";};
    "2019L"=@{"sqlversion"="2019";"image"="mcr.microsoft.com/mssql/server:2019-latest";}    
    "2022L"=@{"sqlversion"="2022";"image"="mcr.microsoft.com/mssql/server:2022-latest";}    
};

$SQLVersionEditionInfo = $SQLVersionEditionHash.$SQLVersionEdition;
Log-Output "SQLVersionEditionInfo:  ", $SQLVersionEditionInfo;
$ContainerName = ("C{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','').ToLower()
$ContainerImage = $SQLVersionEditionInfo.image

Log-Output 'Creating SQL Server Container resources'

$templatePath = (Join-Path $invocationDir 'CreateSQLContainerTemplate.bicep' | Resolve-Path);
Log-Output "*---------------*";
Log-Output (Get-InstalledModule -Name Az|Out-String);
Log-Output (bicep --version|Out-String);
Log-Output (get-module -name az.resources -listavailable|Out-String);
Log-Output ($psversiontable|Out-String);
Log-Output ($env:PSModulePath -split ";"|Out-String);
Log-Output "*---------------*";
Log-Output $templatePath
Log-Output "*---------------*";

$deploymentResult = (az deployment sub create --location $Location --template-file $templatePath --parameters location=$Location containerName=$ContainerName sqlServerImage=$ContainerImage newResourceGroupName=$ResourceGroupName saPassword=$SQLPwd );

Log-Output 'Done: Creating SQL Server Container'
Log-Output 'Prep SQL Server for tSQLt Build'
# $deploymentResult
$outputs = ($deploymentResult|ConvertFrom-Json).properties.outputs
$ipAddress = $outputs.ipAddress.value
$Port = $outputs.Port.value
Log-Output "*---------------*";
Log-Output "SQL Server address: $ipAddress,$Port"
Log-Output "*---------------*";

$GetSQLVersionPath = (Join-Path $invocationDir 'GetSQLServerVersion.sql' | Resolve-Path);
$DS = Invoke-Sqlcmd -InputFile $GetSQLVersionPath -ServerInstance "$ipAddress,$Port" -Username "$SQLUserName" -Password "$SQLPwd" -TrustServerCertificate -As DataSet
$DS.Tables[0].Rows | ForEach-Object{ Log-Output "{ $($_['LoginName']), $($_['TimeStamp']), $($_['VersionDetail']), $($_['ProductVersion']), $($_['ProductLevel']), $($_['SqlVersion']) }" }

$ActualSQLVersion = $DS.Tables[0].Rows[0]['SqlVersion'];
Log-Output "Actual SQL Version:",$ActualSQLVersion;

Log-Output 'Done: Prep SQL Server for tSQLt Build';

Return @{
    "ContainerName"="$ContainerName";
    "ResourceGroupName"="$ResourceGroupName";
    "SQLFQDN"="$ipAddress";              ##[vmname].[region].cloudapp.azure.com
    "SQLPort"="$SQLPort";                   ##1433
    "SQLVersionEdition"="$SQLVersionEdition"; ##2012Ent
};