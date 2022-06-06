# script to deploy ssis ispac file and run the file as a Windows Authenticated user on the SQL Server machine.
# Adapted from https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-deploy-powershell?view=sql-server-ver15
# Adapted most recently from https://github.com/teach-for-america/ssiscicd/blob/master/docker/mssqlssis/deploy_ssis_package.ps1

param(
	[string]$IspacUrl,
    [string]$TargetFolderName,
    [string]$ProjectFile,
    [string]$ProjectName
)

# Load the IntegrationServices Assembly  
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices")  

# Store the IntegrationServices Assembly namespace to avoid typing it every time  
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"  

# Create a connection to the server  
$sqlConnectionString = "Data Source=localhost;Initial Catalog=master;Integrated Security=SSPI;"  
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
Write-Host "Connecting to server ..."  
Write-Host "connection string: "+$sqlConnectionString 
Write-Host "connection: "+$sqlConnection 

# Create the Integration Services object  
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection
Write-Host "IntegrationServices object: "+$integrationServices 

# Get the Integration Services catalog
$catalog = $integrationServices.Catalogs["SSISDB"]
Write-Host "Catalog: " +$catalog

# Wait till catalog is available
while ($true){
    # Get the Integration Services catalog
    $catalog = $integrationServices.Catalogs["SSISDB"]
    if(!$catalog){
        Write-Verbose "Waiting for create SSISDB Catalog to complete."
        Start-Sleep -Seconds 5        
    }
    else {
        break
        Write-Verbose "SSIS Catalog is available."
    }
}

$folder = $catalog.Folders[$TargetFolderName]

if(!$folder){
    # Create the target folder
    $folder = New-Object $ISNamespace".CatalogFolder" ($catalog, $TargetFolderName, "Folder description")
    $folder.Create()
    Write-Host "Folder created: " + $folder
} else {
    Write-Host "Folder exists: " + $folder
}

# $IspacUrl - url to download from Azure blob storage
Write-Host "Downloading " $IspacUrl " ispac file ..."

$targetDir = "C:\SSIS_ISPACS";

if( -Not (Test-Path -Path $targetDir ) ) {
    New-Item -ItemType directory -Path $targetDir
    Write-Host "Folder created: " + $targetDir
}
else {
    Write-Host "$targetDir Folder exists: "
}

Invoke-WebRequest -Uri $IspacUrl -UseBasicParsing -OutFile "C:\SSIS_ISPACS\$ProjectFile"

$ProjectFilePath="C:\SSIS_ISPACS\$ProjectFile"

Write-Host "Folder: " + $folder
Write-Host "Deploying " $ProjectName " project ..."
Write-Host "From " $ProjectFilePath " project file path..."

# Read the project file and deploy it
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)

# Get the project
$project = $folder.Projects[$ProjectName]

Write-Host "Project deployment complete... " $project "..."

Write-Host "Done."