Param( [string] $ResourceGroupName, [string] $VMName)

#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "x<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host $ResourceGroupName;
Write-Host $VMName;
Write-Host "x<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host $env:UserName
Write-Host $env:UserDomain
Write-Host $env:ComputerName
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";

$labAzResource = (Get-AzResource -Name $VMName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $ResourceGroupName)
##Get-AzResource -Name "V1062sql2014sp3" -ResourceType "Microsoft.DevTestLab/labs/virtualmachines" -ResourceGroupName "tSQLtCI_DevTestLab_20200320_1062"
$labAzResource
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";

Write-Host $labAzResource.Properties.toString()

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

