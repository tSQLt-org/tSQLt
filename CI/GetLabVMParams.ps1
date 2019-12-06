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
Write-Host "labVmComputeId:" $labVmComputeId

# Get lab VM resource group name
$labVmRgName = (Get-AzResource -Id $labVmComputeId).ResourceGroupName
Write-Host "labVmRgName:" $labVmRgName
# Set a variable labVmRgName to store the lab VM resource group name
Write-Host "##vso[task.setvariable variable=labVmRgName;]$labVmRgName"

# Get the lab VM Name
$labVmName = (Get-AzResource -Id $labVmId).Name
Write-Host "labVmName:" $labVmName

# Get lab VM public IP address
$labVMIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).IpAddress
Write-Host "labVMIpAddress:" $labVMIpAddress

# Set a variable labVMIpAddress to store the lab VM Ip address
Write-Host "##vso[task.setvariable variable=labVMIpAddress;]$labVMIpAddress"

# Get lab VM FQDN
$labVMFqdn = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).DnsSettings.Fqdn
Write-Host "labVMFqdn:" $labVMFqdn

# Set a variable labVMFqdn to store the lab VM FQDN name
Write-Host "##vso[task.setvariable variable=labVMFqdn;]$labVMFqdn"