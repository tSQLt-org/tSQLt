Param( [string] $labVmId)

#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "x<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host $labVmId;
Write-Host "x<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host $env:UserName
Write-Host $env:UserDomain
Write-Host $env:ComputerName
Write-Host "<-><-><-><-><-><-><-><-><-><-><-><-><-><->";

$labAzResource = (Get-AzResource -Id $labVmId)

Write-Host $labAzResource.Properties.toString()

$labVmComputeId = (Get-AzResource -Id $labVmId).Properties.ComputeId
Write-Host "setting variable: labVmComputeId:" $labVmComputeId
Write-Host "##vso[task.setvariable variable=labVmComputeId;]$labVmComputeId"

$labVmRgName = (Get-AzResource -Id $labVmComputeId).ResourceGroupName
Write-Host "setting variable: labVmRgName:" $labVmRgName
Write-Host "##vso[task.setvariable variable=labVmRgName;]$labVmRgName"

$labVmName = (Get-AzResource -Id $labVmId).Name
Write-Host "setting labVmName: labVMIpAddress:" $labVMIpAddress
Write-Host "##vso[task.setvariable variable=labVmName;]$labVmName"

$labVMIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).IpAddress
Write-Host "setting variable: labVMIpAddress:" $labVMIpAddress
Write-Host "##vso[task.setvariable variable=labVMIpAddress;]$labVMIpAddress"

$labVMFqdn = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).DnsSettings.Fqdn
Write-Host "setting variable: labVMFqdn:" $labVMFqdn
Write-Host "##vso[task.setvariable variable=labVMFqdn;]$labVMFqdn"