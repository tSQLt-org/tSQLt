##$(DevTestLabRGName)
##$(DevTestLabName)
##$(vmName)
##$(DevTestLabVNetName)
##$(DevTestLabVNetSubnetName)
##${{ parameters.SQLVersion }}
Param( [string] $DTLRGName, [string] $DTLName, [string] $DTLVmName, [string] $DTLVNetName, [string] $DTLVNetSubnetName, [string] $SQLPort, [string] $SQLVersionEdition)


Write-Host "<->1<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Parameters:";
Write-Host "DTLRGName:" $DTLRGName;
Write-Host "DTLName:" $DTLName;
Write-Host "DTLVmName:" $DTLVmName;
Write-Host "DTLVNetName:" $DTLVNetName;
Write-Host "DTLVNetSubnetName:" $DTLVNetSubnetName;
Write-Host "SQLVersionEdition:" $SQLVersionEdition;
Write-Host "<->2<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Execution Environment"
Write-Host "UserName:"     $env:UserName
Write-Host "UserDomain:"   $env:UserDomain
Write-Host "ComputerName:" $env:ComputerName
Write-Host "<->3<-><-><-><-><-><-><-><-><-><-><-><-><->";


##Set-Location $(Build.Repository.LocalPath)
Write-Host 'Creating New VM'
##Set-PSDebug -Trace 1;
$VMResourceGroupDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$DTLRGName" -TemplateFile "CreateVMTemplate.json" -labName "$DTLName" -newVMName "$DTLVmName" -DevTestLabVirtualNetworkName "$DTLVNetName" -DevTestLabVirtualNetworkSubNetName "$DTLVNetSubnetName" -userName "$env:USER_NAME" -password "$env:PASSWORD" -ContactEmail "$env:CONTACT_EMAIL" -SQLVersionEdition "$SQLVersionEdition"
      
Write-Host "+AA++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$VMResourceGroupDeployment
Write-Host "------"
$VMResourceGroupDeployment.Outputs
Write-Host "------"
$SQLVersion = $VMResourceGroupDeployment.Outputs.SQLVersion.Value;
Write-Host ("--->VMResourceGroupDeployment.Outputs.SQLVersion:{0}" -f $SQLVersion)

$labVMId = $VMResourceGroupDeployment.Outputs.labVMId.Value;
Write-Host ("--->VMResourceGroupDeployment.Outputs.vmId:{0}" -f $labVMId)

$VmComputeId = (Get-AzResource -id $labVMId).Properties.ComputeId;
Write-Host ("--->VmComputeId:{0}" -f $VmComputeId)
Write-Host "+BB++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$ComputeRGN = (Get-AzResource -id $VmComputeId).ResourceGroupName
Write-Host ("--->ComputeRGN:{0}" -f $ComputeRGN)
Write-Host "+CC++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Set-AzResourceGroup -Name $ComputeRGN -Tags @{"Department"="tSQLtCI";"ParentRGN"="$DTLRGName"}
Write-Host "+DD++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

##Set-PSDebug -Trace 0;
Write-Host 'Finished Creating New VM'

#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Host "Getting VM Resource Parameters";

##(Get-AzResource -ResourceId (Get-AzResource -Name V1087sql2014sp3 -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName tSQLtCI_DevTestLab_20200323_1087_RG).ResourceId)
$labAzResource = (Get-AzResource -ResourceId (Get-AzResource -Name $DTLVmName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $DTLRGName).ResourceId)

$labAzResource
Write-Host "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";

$labVmComputeId = $labAzResource.Properties.ComputeId
Write-Host "setting variable: labVmComputeId:" $labVmComputeId
Write-Host "##vso[task.setvariable variable=labVmComputeId;]$labVmComputeId"

$labVmRgName = (Get-AzResource -Id $labVmComputeId).ResourceGroupName
Write-Host "setting variable: labVmRgName:" $labVmRgName
Write-Host "##vso[task.setvariable variable=labVmRgName;]$labVmRgName"

$labVmName = $labAzResource.Name
Write-Host "setting variable: labVmName:" $labVmName
Write-Host "##vso[task.setvariable variable=labVmName;]$labVmName"

$labVMId = $labAzResource.ResourceId
Write-Host 'labVMId: ' $labVMId
Write-Host "##vso[task.setvariable variable=labVMId;]$labVMId"

$PublicIpAddress= (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName)
$labVMIpAddress = $PublicIpAddress.IpAddress
Write-Host "setting variable: labVMIpAddress:" $labVMIpAddress
Write-Host "##vso[task.setvariable variable=labVMIpAddress;]$labVMIpAddress"

$labVMFqdn = $PublicIpAddress.DnsSettings.Fqdn
Write-Host "setting variable: labVMFqdn:" $labVMFqdn
Write-Host "##vso[task.setvariable variable=labVMFqdn;]$labVMFqdn"

Write-Host "Tagging Resource Group";

Set-AzResourceGroup -Name $DTLRGName -Tags @{"SQLVmFQDN"="$labVMFqdn";"SQLVmPort"="$SQLPort";"SQLVersionEdition"="$SQLVersionEdition";"SQLVersion"="$SQLVersion";}
