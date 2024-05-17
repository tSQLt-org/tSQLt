param location string = resourceGroup().location
param containerName string 
param sqlServerImage string 
param cpu int
param memory int
@secure()
param saPassword string 

var containerGroupName = '${containerName}-group'
var sqlPort = 1433

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: sqlServerImage
          resources: {
            requests: {
              cpu: cpu
              memoryInGB: memory
            }
          }
          environmentVariables: [
            {
              name: 'ACCEPT_EULA'
              value: 'Y'
            }
            {
              name: 'MSSQL_SA_PASSWORD'
              secureValue: saPassword
            }
          ]
          ports: [
            {
              port: sqlPort
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'tcp'
          port: sqlPort
        }
      ]
    }
  }
}

output ipAddress string = containerGroup.properties.ipAddress.ip
output Port int = containerGroup.properties.ipAddress.ports[0].port
