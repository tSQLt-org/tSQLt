Param( [string] $ResourceGroupName, [string] $VMName)

#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Host "<->1<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Parameters:";
Write-Host "ResourceGroupName:" $ResourceGroupName;
Write-Host "VMName:"            $VMName;
Write-Host "<->2<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Execution Environment"
Write-Host "UserName:"     $env:UserName
Write-Host "UserDomain:"   $env:UserDomain
Write-Host "ComputerName:" $env:ComputerName
Write-Host "<->3<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "VM Resource";

##(Get-AzResource -ResourceId (Get-AzResource -Name V1087sql2014sp3 -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName tSQLtCI_DevTestLab_20200323_1087_RG).ResourceId)
$labAzResource = (Get-AzResource -ResourceId (Get-AzResource -Name $VMName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $ResourceGroupName).ResourceId)

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

