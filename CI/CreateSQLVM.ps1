<# USAGE: ./CreateSQLVM.ps1 -Location "East US 2" -Size "Standard_D2as_v4" -NamePreFix "test" -VMAdminName "azureAdminName" -VMAdminPwd "aoeihag;ladjfalkj23" -SQLVersionEdition "2017" -SQLPort "41433" -SQLUserName "tSQLt_sa" -SQLPwd "aoeihag;ladjfalkj46" -BuildId "001" #>
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Location,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Size,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $NamePreFix,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $VMAdminName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $VMAdminPwd,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLVersionEdition,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPort,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLUserName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPwd
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
"FileLocation: $dir"

.($dir+"/CommonFunctionsAndMethods.ps1")


Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "<->                                             <->";
Log-Output "<->                  START 1                    <->";
Log-Output "<->                                             <->";
Log-Output "<-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Parameters:";
Log-Output "NamePreFix:", $NamePreFix;
Log-Output "Location:", $Location;
Log-Output "Size:", $Size;
Log-Output "BuildId:", $BuildId;
Log-Output "SQLVersionEdition:", $SQLVersionEdition;
Log-Output "SQLPort:", $SQLPort;
Log-Output "<-> END 1 <-><-><-><-><-><-><-><-><-><-><-><-><->";

$ResourceBaseName = ("$NamePreFix" + (Get-Date).tostring('yyyyMMdd') + "_" + $SQLVersionEdition + "_" + $BuildId);
$ResourceGroupName = $ResourceBaseName+'_RG';
$VNetName = $ResourceBaseName+'_VNet';
$SubnetName = $ResourceBaseName + '_Subnet'
$VMName = ("V{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','')
$PipName = $ResourceBaseName + '_' + $(Get-Random);
$NsgName = $ResourceBaseName + '_nsg';
$InterfaceName = $ResourceBaseName + '_nic';



#[string] $ResourceGroupName, [string] $ResourceBaseName, [string] $VMName, [string] $VNetName, [string] $DTLVNetSubnetName
Log-Output "<-> START 2 <-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Names:";
Log-Output "ResourceBaseName:    ", $ResourceBaseName;
Log-Output "ResourceGroupName:  ", $ResourceGroupName;
Log-Output "VMName:  ", $VMName;
Log-Output "VNetName:  ", $VNetName;
Log-Output "SubnetName:  ", $SubnetName;
Log-Output "PipName:  ", $PipName;
Log-Output "NsgName:  ", $NsgName;
Log-Output "InterfaceName:  ", $InterfaceName;
Log-Output "<-> END 2 <-><-><-><-><-><-><-><-><-><-><-><-><->";

<# FYI Usage: $SQLVersionEditionHash.$SQLVersionEdition.offer = "SQL2016SP2-WS2016" #>
$SQLVersionEditionHash = @{
    "2008R2Ent"=@{"sqlversion"="2008R2";"offer"="SQL2008R2SP3-WS2008R2SP1";"publisher"="microsoftsqlserver";"sku"="Enterprise";"osType"="Windows";"version"="latest"};
    "2008R2Std"=@{"sqlversion"="2008R2";"offer"="SQL2008R2SP3-WS2008R2SP1";"publisher"="microsoftsqlserver";"sku"="Standard";"osType"="Windows";"version"="latest"};
    "2012Ent"=@{"sqlversion"="2012";"offer"="SQL2012SP4-WS2012R2";"publisher"="microsoftsqlserver";"sku"="Enterprise";"osType"="Windows";"version"="latest"};
    "2014"=@{"sqlversion"="2014";"offer"="sql2014sp3-ws2012r2";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"};
    "2016"=@{"sqlversion"="2016";"offer"="SQL2016SP2-WS2016";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"};
    "2017"=@{"sqlversion"="2017";"offer"="sql2017-ws2019";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"};
    "2019"=@{"sqlversion"="2019";"offer"="sql2019-ws2019";"publisher"="microsoftsqlserver";"sku"="sqldev";"osType"="Windows";"version"="latest"}    
};

$SQLVersionEditionInfo = $SQLVersionEditionHash.$SQLVersionEdition;
Log-Output "SQLVersionEditionInfo:  ", $SQLVersionEditionInfo;

Log-Output "Creating Resource Group $ResourceGroupName";
New-AzResourceGroup -Name "$ResourceGroupName" -Location "$Location" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force|Out-String|Log-Output;
Log-Output "DONE: Creating Resource Group $ResourceGroupName";

Log-Output "Creating SubnetConfig";
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24;
Log-Output "DONE: Creating SubnetConfig";

Log-Output "Creating VNet";
# Create a virtual network
$Vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix 192.168.0.0/16 -Subnet $SubnetConfig;
Log-Output "DONE: Creating VNet";

Log-Output "Creating PIP";
# Create a public IP address and specify a DNS name
$Pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $PipName;
$FQDN = $Pip.IpAddress;
Log-Output "FQDN: ", $FQDN;
Log-Output "DONE: Creating PIP";

Log-Output "Creating NSG";
# Rule to allow remote desktop (RDP)
$NsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp `
   -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow;

#Rule to allow SQL Server connections on port $SQLPort
$NsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp `
   -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange $SQLPort -Access Allow;

# Create the network security group
$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
   -Location $Location -Name $NsgName `
   -SecurityRules $NsgRuleRDP,$NsgRuleSQL;
Log-Output "DONE: Creating NSG";

Log-Output "Creating NIC";
# Create the Network Interface
$Interface = New-AzNetworkInterface -Name $InterfaceName `
    -ResourceGroupName $ResourceGroupName -Location $Location `
    -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id `
    -NetworkSecurityGroupId $Nsg.Id
Log-Output "DONE: Creating NIC";

$VNet|Out-String|Log-Output;

Log-Output "Creating VM";
# Define a credential object
$SecurePassword = ConvertTo-SecureString $VMAdminPwd -AsPlainText -Force;
$VMCredentials = New-Object System.Management.Automation.PSCredential ($VMAdminName, $securePassword);

Log-Output "*-**-*";

# Create a virtual machine configuration
$VMConfig = New-AzVMConfig -VMName $VMName -VMSize $Size |
   Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential $VMCredentials -ProvisionVMAgent -EnableAutoUpdate |
   Set-AzVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer $SQLVersionEditionInfo.offer -Skus $SQLVersionEditionInfo.sku -Version $SQLVersionEditionInfo.version |
   Add-AzVMNetworkInterface -Id $Interface.Id

Log-Output "*-**-*";

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMConfig;
$VM = (Get-AzResource -Name $VMName -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $ResourceGroupName);
$VmResourceId = $VM.ResourceId;
Log-Output "VmResourceId: ", $VmResourceId;

Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName | Select IpAddress;

Log-Output "DONE: Creating VM";
Log-Output 'Applying SqlVM Config'

##Set-PSDebug -Trace 1;
$SQLVM = New-AzResourceGroupDeployment -ResourceGroupName "$ResourceGroupName" -TemplateFile "$dir/CreateSQLVirtualMachineTemplate.json" -sqlPortNumber "$SQLPort" -sqlAuthenticationLogin "$SQLUserName" -sqlAuthenticationPassword "$SQLPwd" -newVMName "$VMName" -newVMRID "$VmResourceId"
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