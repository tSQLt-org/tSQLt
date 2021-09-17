<# USAGE: ./CreateSQLVM.ps1 -Location "East US 2" -Size "Standard_D2as_v4" -ResourceGroupName "myTestResourceGroup" -VMAdminName "azureAdminName" -VMAdminPwd "aoeihag;ladjfalkj23" -SQLVersionEdition "2017" -SQLPort "41433" -SQLUserName "tSQLt_sa" -SQLPwd "aoeihag;ladjfalkj46" -BuildId "001" #>
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Location,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Size,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ResourceGroupName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $VMAdminName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $VMAdminPwd,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLVersionEdition,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPort,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLUserName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPwd
);

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
$projectDir = Split-Path (Split-Path $dir);

.($projectDir+"\Build\CommonFunctionsAndMethods.ps1")
Log-Output "FileLocation: ", $dir;
Log-Output "Project Location: ", $projectDir;


Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "<->                                             <->";
Log-Output "<->                  START 1                    <->";
Log-Output "<->                                             <->";
Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Parameters:";
Log-Output "ResourceGroupName:", $ResourceGroupName;
Log-Output "Location:", $Location;
Log-Output "Size:", $Size;
Log-Output "BuildId:", $BuildId;
Log-Output "SQLVersionEdition:", $SQLVersionEdition;
Log-Output "SQLPort:", $SQLPort;
Log-Output "<-> END 1 <-><-><-><-><-><-><-><-><-><-><-><-><->";

$VNetName = $ResourceGroupName+'_VNet';
$SubnetName = $ResourceGroupName + '_Subnet'
$VMName = ("V{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','')
$PipName = $ResourceGroupName + '_' + $(Get-Random);
$NsgName = $ResourceGroupName + '_nsg';
$InterfaceName = $ResourceGroupName + '_nic';



#[string] $ResourceGroupName, [string] $ResourceGroupName, [string] $VMName, [string] $VNetName, [string] $DTLVNetSubnetName
Log-Output "<-> START 2 <-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Names:";
Log-Output "ResourceGroupName:    ", $ResourceGroupName;
Log-Output "VMName:  ", $VMName;
Log-Output "VNetName:  ", $VNetName;
Log-Output "SubnetName:  ", $SubnetName;
Log-Output "PipName:  ", $PipName;
Log-Output "NsgName:  ", $NsgName;
Log-Output "InterfaceName:  ", $InterfaceName;
Log-Output "<-> END 2 <-><-><-><-><-><-><-><-><-><-><-><-><->";

<# FYI Usage: $SQLVersionEditionHash.$SQLVersionEdition.offer = "SQL2016SP2-WS2016"
URN for az cli --> $SQLVersionEditionInfo.publisher+":"+$SQLVersionEditionInfo.offer+":"+$SQLVersionEditionInfo.sku+":"+$SQLVersionEditionInfo.version
#>
$SQLVersionEditionHash = @{
    "2008R2Std"=@{"sqlversion"="2008R2";"offer"="SQL2008R2SP3-WS2008R2SP1";"publisher"="microsoftsqlserver";"sku"="Standard";"osType"="Windows";"version"="latest"}; #MicrosoftSQLServer:SQL2008R2SP3-WS2008R2SP1:Standard:latest
    "2012Ent"=@{"sqlversion"="2012";"offer"="SQL2012SP4-WS2012R2";"publisher"="microsoftsqlserver";"sku"="Enterprise";"osType"="Windows";"version"="latest"}; #MicrosoftSQLServer:SQL2012SP4-WS2012R2:Enterprise:latest
    "2014"=@{"sqlversion"="2014";"offer"="sql2014sp3-ws2012r2";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"}; #MicrosoftSQLServer:sql2014sp3-ws2012r2:sqldev:latest
    "2016"=@{"sqlversion"="2016";"offer"="SQL2016SP2-WS2016";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"}; #MicrosoftSQLServer:sql2016sp2-ws2019:sqldev:latest
    "2017"=@{"sqlversion"="2017";"offer"="sql2017-ws2019";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"}; #MicrosoftSQLServer:sql2017-ws2019:sqldev:latest
    "2019"=@{"sqlversion"="2019";"offer"="sql2019-ws2019";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"} #MicrosoftSQLServer:sql2019-ws2019:sqldev:latest
};

$SQLVersionEditionInfo = $SQLVersionEditionHash.$SQLVersionEdition;
$ImageUrn = $SQLVersionEditionInfo.publisher+":"+$SQLVersionEditionInfo.offer+":"+$SQLVersionEditionInfo.sku+":"+$SQLVersionEditionInfo.version;
Log-Output "SQLVersionEditionInfo:  ", $SQLVersionEditionInfo;

Log-Output "Creating Resource Group $ResourceGroupName";
<#
az group create --location
                --name
                [--managed-by]
                [--subscription]
                [--tags]
#>
# New-AzResourceGroup -Name "$ResourceGroupName" -Location "$Location" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force|Out-String|Log-Output;
az group create --location "$Location" --name "$ResourceGroupName"
Log-Output "DONE: Creating Resource Group $ResourceGroupName";

#Log-Output "Creating SubnetConfig";
# Create a subnet configuration
<#
az network vnet subnet create --address-prefixes
                              --name
                              --resource-group
                              --vnet-name
                              [--defer]
                              [--delegations]
                              [--disable-private-endpoint-network-policies {false, true}]
                              [--disable-private-link-service-network-policies {false, true}]
                              [--nat-gateway]
                              [--network-security-group]
                              [--route-table]
                              [--service-endpoint-policy]
                              [--service-endpoints]
                              [--subscription]
#>
#$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24;
#Log-Output "DONE: Creating SubnetConfig";

Log-Output "Creating VNet";
# Create a virtual network
<#
az network vnet create --name
                       --resource-group
                       [--address-prefixes]
                       [--ddos-protection {false, true}]
                       [--ddos-protection-plan]
                       [--defer]
                       [--dns-servers]
                       [--edge-zone]
                       [--flowtimeout]
                       [--location]
                       [--network-security-group]
                       [--subnet-name]
                       [--subnet-prefixes]
                       [--subscription]
                       [--tags]
                       [--vm-protection {false, true}]
#>
# $Vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix 192.168.0.0/16 -Subnet $SubnetConfig;
az network vnet create --name "$VNetName" --resource-group "$ResourceGroupName" --location $Location --address-prefixes 192.168.0.0/16 --subnet-name "$SubnetName" --subnet-prefixes 192.168.1.0/24

Log-Output "DONE: Creating VNet";

Log-Output "Creating PIP";
# Create a public IP address and specify a DNS name
<#
az network public-ip create --name
                            --resource-group
                            [--allocation-method {Dynamic, Static}]
                            [--dns-name]
                            [--edge-zone]
                            [--idle-timeout]
                            [--ip-address]
                            [--ip-tags]
                            [--location]
                            [--public-ip-prefix]
                            [--reverse-fqdn]
                            [--sku {Basic, Standard}]
                            [--subscription]
                            [--tags]
                            [--tier {Global, Regional}]
                            [--version {IPv4, IPv6}]
                            [--zone {1, 2, 3}]
#>
# $Pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $PipName;
az network public-ip create --name $PipName --resource-group $ResourceGroupName --allocation-method Static --idle-timeout 4 --location $Location 
#$FQDN = $Pip.IpAddress;
$FQDN = (az network public-ip show --resource-group $ResourceGroupName --name $PipName --query "ipAddress" --output tsv)
Log-Output "FQDN: ", $FQDN;
Log-Output "DONE: Creating PIP";

Log-Output "Creating NSG";
# Rule to allow remote desktop (RDP)
<#
az network nsg rule create --name
                           --nsg-name
                           --priority
                           --resource-group
                           [--access {Allow, Deny}]
                           [--description]
                           [--destination-address-prefixes]
                           [--destination-asgs]
                           [--destination-port-ranges]
                           [--direction {Inbound, Outbound}]
                           [--protocol {*, Ah, Esp, Icmp, Tcp, Udp}]
                           [--source-address-prefixes]
                           [--source-asgs]
                           [--source-port-ranges]
                           [--subscription]

az network nsg rule create -g MyResourceGroup --nsg-name MyNsg -n MyNsgRule --priority 4096 \
    --source-address-prefixes 208.130.28.0/24 --source-port-ranges 80 \
    --destination-address-prefixes '*' --destination-port-ranges 80 8080 --access Deny \
    --protocol Tcp --description "Deny from specific IP address ranges on 80 and 8080."
#>

# $NsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp `
#    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
#    -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow;

# #Rule to allow SQL Server connections on port $SQLPort
# $NsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp `
#    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
#    -DestinationAddressPrefix * -DestinationPortRange $SQLPort -Access Allow;

# Create the network security group
<#
az network nsg create --name
                      --resource-group
                      [--location]
                      [--subscription]
                      [--tags]

az network nsg create -g MyResourceGroup -n MyNsg --tags super_secure no_80 no_22
#>
<#
$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
   -Location $Location -Name $NsgName `
   -SecurityRules $NsgRuleRDP,$NsgRuleSQL;
#>

az network nsg create --name $NsgName --resource-group $ResourceGroupName --location $Location 
az network nsg rule create --name "RDPRule" --nsg-name $NsgName --priority 1000 --resource-group $ResourceGroupName --access Allow --destination-address-prefixes * --destination-port-ranges 3389 --direction Inbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "MSSQLRule" --nsg-name $NsgName --priority 1001 --resource-group $ResourceGroupName --access Allow --destination-address-prefixes * --destination-port-ranges $SQLPort --direction Inbound --protocol Tcp --source-address-prefixes * --source-port-ranges *

Log-Output "DONE: Creating NSG";

Log-Output "Creating NIC";
# Create the Network Interface
<#
az network nic create --name
                      --resource-group
                      --subnet
                      [--accelerated-networking {false, true}]
                      [--app-gateway-address-pools]
                      [--application-security-groups]
                      [--dns-servers]
                      [--edge-zone]
                      [--gateway-name]
                      [--internal-dns-name]
                      [--ip-forwarding {false, true}]
                      [--lb-address-pools]
                      [--lb-inbound-nat-rules]
                      [--lb-name]
                      [--location]
                      [--network-security-group]
                      [--no-wait]
                      [--private-ip-address]
                      [--private-ip-address-version {IPv4, IPv6}]
                      [--public-ip-address]
                      [--subscription]
                      [--tags]
                      [--vnet-name]

az network nic create -g MyResourceGroup --vnet-name MyVnet --subnet MySubnet -n MyNic \
    --ip-forwarding --network-security-group MyNsg
#>
# $Interface = New-AzNetworkInterface -Name $InterfaceName `
#     -ResourceGroupName $ResourceGroupName -Location $Location `
#     -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id `
#     -NetworkSecurityGroupId $Nsg.Id

az network nic create --name $InterfaceName --resource-group $ResourceGroupName --subnet $SubnetName --vnet-name $VNetName --location $Location --network-security-group $NsgName --public-ip-address $PipName 

Log-Output "DONE: Creating NIC";

# $VNet|Out-String|Log-Output;

Log-Output "Creating VM";
# Define a credential object
# $SecurePassword = ConvertTo-SecureString $VMAdminPwd -AsPlainText -Force;
# $VMCredentials = New-Object System.Management.Automation.PSCredential ($VMAdminName, $securePassword);

Log-Output "*-**-*";

# Create a virtual machine configuration
<#
az vm create * --name
             * --resource-group
             [--accelerated-networking {false, true}]
             * [--admin-password]
             * [--admin-username]
             [--asgs]
             [--assign-identity]
             [--attach-data-disks]
             [--attach-os-disk]
             [--authentication-type {all, password, ssh}]
             [--availability-set]
             [--boot-diagnostics-storage]
             [--capacity-reservation-group]
             * [--computer-name]
             [--count]
             [--custom-data]
             [--data-delete-option]
             [--data-disk-caching]
             [--data-disk-encryption-sets]
             [--data-disk-sizes-gb]
             [--edge-zone]
             * [--enable-agent {false, true}]
             * [--enable-auto-update {false, true}] specify false, please
             [--enable-hotpatching {false, true}]
             [--enable-secure-boot {false, true}]
             [--enable-vtpm {false, true}]
             [--encryption-at-host {false, true}]
             [--ephemeral-os-disk {false, true}]
             [--eviction-policy {Deallocate, Delete}]
             [--generate-ssh-keys]
             [--host]
             [--host-group]
             * [--image]
             [--license-type {None, RHEL_BYOS, SLES_BYOS, Windows_Client, Windows_Server}]
             * [--location]
             [--max-price]
             [--nic-delete-option]
             * [--nics]
             [--no-wait]
             [--nsg]
             [--nsg-rule {NONE, RDP, SSH}]
             [--os-disk-caching {None, ReadOnly, ReadWrite}]
             [--os-disk-delete-option {Delete, Detach}]
             [--os-disk-encryption-set]
             [--os-disk-name]
             [--os-disk-size-gb]
             * [--os-type {linux, windows}]
             [--patch-mode {AutomaticByOS, AutomaticByPlatform, ImageDefault, Manual}]
             [--plan-name]
             [--plan-product]
             [--plan-promotion-code]
             [--plan-publisher]
             [--platform-fault-domain]
             [--ppg]
             * [--priority {Low, Regular, Spot}]
             [--private-ip-address]
             [--public-ip-address]
             [--public-ip-address-allocation {dynamic, static}]
             [--public-ip-address-dns-name]
             [--public-ip-sku {Basic, Standard}]
             [--role]
             [--scope]
             [--secrets]
             [--security-type {TrustedLaunch}]
             * [--size]
             [--specialized {false, true}]
             [--ssh-dest-key-path]
             [--ssh-key-name]
             [--ssh-key-values]
             [--storage-account]
             [--storage-container-name]
             [--storage-sku]
             [--subnet]
             [--subnet-address-prefix]
             [--subscription]
             [--tags]
             [--ultra-ssd-enabled {false, true}]
             [--use-unmanaged-disk]
             [--user-data]
             [--validate]
             [--vmss]
             [--vnet-address-prefix]
             [--vnet-name]
             [--workspace]
             [--zone {1, 2, 3}]




#>
# $VMConfig = New-AzVMConfig -VMName $VMName -VMSize $Size -Priority "Spot" |
#    Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential $VMCredentials -ProvisionVMAgent -EnableAutoUpdate |
#    Set-AzVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer $SQLVersionEditionInfo.offer -Skus $SQLVersionEditionInfo.sku -Version $SQLVersionEditionInfo.version |
#    Add-AzVMNetworkInterface -Id $Interface.Id

Log-Output "*-**-*";

# Create the VM
# $VMInfo = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMConfig;
az vm create --name $VMName --resource-group $ResourceGroupName --location $Location --admin-password $VMAdminPwd --admin-username $VMAdminName --computer-name $VMName --enable-agent true --enable-auto-update false --image $ImageUrn --nics $InterfaceName --priority Spot --size $Size

# $VM = (Get-AzResource -Name $VMName -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $ResourceGroupName);
# $VmResourceId = $VM.ResourceId;
$VMResourceId = (az vm show --resource-group $ResourceGroupName --name $VMName --query id --output tsv)
Log-Output "VmResourceId: ", $VmResourceId;

# $PiPInfo = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName;

Log-Output "DONE: Creating VM";
Log-Output 'Applying SqlVM Config'

##Set-PSDebug -Trace 1;
$sqlVMParameters = @{
    "sqlPortNumber" = $SQLPort
    "sqlAuthenticationLogin" = "$SQLUserName"
    "sqlAuthenticationPassword" = "$SQLPwd"
    "newVMName" = "$VMName"
    "newVMRID" = "$VmResourceId"
};

Log-Output "*---------------*";
Log-Output (Get-InstalledModule -Name Az|Out-String);
Log-Output (bicep --version|Out-String);
Log-Output (get-module -name az.resources -listavailable|Out-String);
Log-Output ($psversiontable|Out-String);
Log-Output ($env:PSModulePath -split ";"|Out-String);
Log-Output "*---------------*";
Log-Output "$dir/CreateSQLVirtualMachineTemplate.bicep"
Log-Output (Get-Item -Path "$dir/CreateSQLVirtualMachineTemplate.bicep"|Out-String);
Log-Output "*---------------*";

#$SQLVM = New-AzResourceGroupDeployment -ResourceGroupName "$ResourceGroupName" -TemplateFile "$dir/CreateSQLVirtualMachineTemplate.json" -sqlPortNumber "$SQLPort" -sqlAuthenticationLogin "$SQLUserName" -sqlAuthenticationPassword "$SQLPwd" -newVMName "$VMName" -newVMRID "$VmResourceId"
#$SQLVM = New-AzResourceGroupDeployment -ResourceGroupName "$ResourceGroupName" -TemplateFile "$dir/CreateSQLVirtualMachineTemplate.bicep" -TemplateParameterObject $sqlVMParameters -Debug;
az deployment group create --resource-group $ResourceGroupName --template-file "$dir/CreateSQLVirtualMachineTemplate.bicep" --parameters sqlPortNumber=$SQLPort sqlAuthenticationLogin="$SQLUserName" sqlAuthenticationPassword="$SQLPwd" newVMName="$VMName" newVMRID="$VmResourceId"

$SQLVM|Out-String|Log-Output;

Log-Output 'Done: Applying SqlVM Config'
Log-Output 'Prep SQL Server for tSQLt Build'


$DS = Invoke-Sqlcmd -InputFile "$dir/GetSQLServerVersion.sql" -ServerInstance "$FQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPwd" -As DataSet
$DS.Tables[0].Rows | %{ Log-Output "{ $($_['LoginName']), $($_['TimeStamp']), $($_['VersionDetail']), $($_['ProductVersion']), $($_['ProductLevel']), $($_['SqlVersion']) }" }

$ActualSQLVersion = $DS.Tables[0].Rows[0]['SqlVersion'];
Log-Output "Actual SQL Version:",$ActualSQLVersion;

Log-Output 'Done: Prep SQL Server for tSQLt Build';

Return @{
    "VmName"="$VmName";
    "ResourceGroupName"="$ResourceGroupName";
    "SQLVmFQDN"="$FQDN";              ##[vmname].[region].cloudapp.azure.com
    "SQLVmPort"="$SQLPort";                   ##1433
    "SQLVersionEdition"="$SQLVersionEdition"; ##2012Ent
};