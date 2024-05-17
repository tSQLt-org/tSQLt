targetScope='subscription'

param location string = 'eastus2'
param newResourceGroupName string = 'sqlserver-container-test-rg'
param containerName string = 'sqlserver2022' 
param sqlServerImage string = 'mcr.microsoft.com/mssql/server:2022-latest' 
@secure()
param saPassword string 
param cpu int = 4
param memory int = 8


resource newResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: newResourceGroupName
  location: location
  tags: {
    Department: 'tSQLtCI'
    Ephemeral: 'True'
  }
}


module containers './CreateSQLContainerAndIpAddressModule.bicep' = {
  name: 'deployContainers'
  scope: newResourceGroup
  params: {
    location: location
    containerName: containerName
    sqlServerImage: sqlServerImage
    cpu:cpu
    memory:memory
    saPassword: saPassword
  }
}

output ipAddress string = containers.outputs.ipAddress
output Port int = containers.outputs.Port
