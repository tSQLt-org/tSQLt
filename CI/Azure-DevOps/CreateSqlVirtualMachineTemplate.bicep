param sqlConnectivityType string = 'Public'
param sqlPortNumber int = 41433
param sqlStorageWorkloadType string = 'DW'
param sqlStorageDisksConfigurationType string = 'ADD'
param sqlAutopatchingDayOfWeek string = 'Sunday'
param sqlAutopatchingStartHour int = 2
param sqlAutopatchingWindowDuration int = 60
param sqlAuthenticationLogin string = 'tSQLt'
param sqlAuthenticationPassword string = 'sdlfksdlkfjlsdkjf39939^'
param newVMName string = 'V1052sql2014sp3'
param newVMRID string = '/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_20200318_1052-V1052sql2014sp3-155797/providers/Microsoft.Compute/virtualMachines/V1052sql2014sp3'

resource newVMName_resource 'Microsoft.SqlVirtualMachine/SqlVirtualMachines@2017-03-01-preview' = {
  name: newVMName
  location: resourceGroup().location
  properties: {
    virtualMachineResourceId: newVMRID
    sqlManagement: 'Full'
    sqlServerLicenseType: 'PAYG'
    autoPatchingSettings: {
      enable: true
      dayOfWeek: sqlAutopatchingDayOfWeek
      maintenanceWindowStartingHour: sqlAutopatchingStartHour
      maintenanceWindowDuration: sqlAutopatchingWindowDuration
    }
    keyVaultCredentialSettings: {
      enable: false
      credentialName: ''
    }
    storageConfigurationSettings: {
      diskConfigurationType: sqlStorageDisksConfigurationType
      storageWorkloadType: sqlStorageWorkloadType
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: sqlConnectivityType
        port: sqlPortNumber
        sqlAuthUpdateUserName: sqlAuthenticationLogin
        sqlAuthUpdatePassword: sqlAuthenticationPassword
      }
    }
  }
}
