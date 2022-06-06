# from https://github.com/teach-for-america/ssiscicd/blob/master/docker/mssqlssis/create_ssis_catalog.ps1
# script to create ssis catalog and deploy ssis ispac file

# Load the IntegrationServices Assembly  
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices")  

# Store the IntegrationServices Assembly namespace to avoid typing it every time  
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"  

Write-Host "Connecting to server ..."  

# Create a connection to the server  
$sqlConnectionString = "Data Source=localhost;Initial Catalog=master;Integrated Security=SSPI;"  
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

Write-Host "connection string: "+$sqlConnectionString 
Write-Host "connection: "+$sqlConnection 

# Create the Integration Services object  
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection

# Provision a new SSIS Catalog  
$catalog = New-Object $ISNamespace".Catalog" ($integrationServices, "SSISDB", "P@assword1")  
$catalog.Create()

Write-Host "Catalog created: "+$catalog 