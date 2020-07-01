##$(DevTestLabRGName)
##$(DevTestLabName)
##$(vmName)
##$(DevTestLabVNetName)
##$(DevTestLabVNetSubnetName)
##${{ parameters.SQLVersion }}
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $NamePreFix,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLVersionEdition,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPort,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LabShutdownNotificationEmail,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LabShutdownNotificationURL,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLUserName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPassword
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Log-Output "FileLocation: $dir"

.($dir+"\CommonFunctionsAndMethods.ps1")


Log-Output "<->1<-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Parameters:";
Log-Output "NamePreFix:", $NamePreFix;
Log-Output "BuildId:", $BuildId;
Log-Output "SQLVersionEdition:", $SQLVersionEdition;
Log-Output "<->2<-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Execution Environment"
Log-Output "UserName:    ", $env:UserName
Log-Output "UserDomain:  ", $env:UserDomain
Log-Output "ComputerName:", $env:ComputerName
Log-Output "<->3<-><-><-><-><-><-><-><-><-><-><-><-><->";

#####################
$DTLName = ("$NamePreFix" + (Get-Date).tostring('yyyyMMdd') + "_" + $SQLVersionEdition + "_" + $BuildId)
$DTLRGName = $DTLName+'_RG'
$DTLVNetName = $DTLName+'_VNet0001'
$DTLVmName = ("V{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','')

#[string] $DTLRGName, [string] $DTLName, [string] $DTLVmName, [string] $DTLVNetName, [string] $DTLVNetSubnetName
Log-Output "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";
Log-Output "Names:";
Log-Output "DTLRGName:  ", $DTLRGName;
Log-Output "DTLName:    ", $DTLName;
Log-Output "DTLVmName:  ", $DTLVmName;
Log-Output "DTLVNetName:", $DTLVNetName;
Log-Output "<->5<-><-><-><-><-><-><-><-><-><-><-><-><->";


Log-Output "Creating Resource Group $DTLRGName"
New-AzResourceGroup -Name "$DTLRGName" -Location "East US 2" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force|Out-String|Log-Output;
Log-Output "DONE: Creating Resource Group $DTLRGName"

Log-Output "Creating VNet $DTLVNetName"
$params = @{
    ResourceGroupName ="$DTLRGName";
    TemplateFile="$dir\CreateVNetTemplate.json";
    VNet_name="$DTLVNetName";
    SQL_Port="$SQLPort";
};
$VNet = New-AzResourceGroupDeployment @params;
$VNet|Out-String|Log-Output;

$DTLVNetSubnetName = $VNet.Outputs.subnetName.Value
Log-Output "DTLVNetSubnetName:", $DTLVNetSubnetName;
Log-Output "DONE: Creating VNet $DTLVNetName"

Log-Output "Creating DTL $DTLName"
$params = @{
    ResourceGroupName="$DTLRGName";
    TemplateFile="$dir\CreateDevTestLabTemplate.json";
    newLabName="$DTLName";
    VNetName="$DTLVNetName";
    SubNetName="$DTLVNetSubnetName";
    labVmShutDownNotificationEmail="$LabShutdownNotificationEmail";
    labVmShutDownNotificationURL="$LabShutdownNotificationURL";
};
New-AzResourceGroupDeployment @params|Out-String|Log-Output;

Log-Output "DONE: Creating DTL $DTLName"

#####################

##Set-Location $(Build.Repository.LocalPath)
Log-Output 'Creating New VM'
##Set-PSDebug -Trace 1;
$VMResourceGroupDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$DTLRGName" -TemplateFile "$dir\CreateVMTemplate.json" -labName "$DTLName" -newVMName "$DTLVmName" -DevTestLabVirtualNetworkName "$DTLVNetName" -DevTestLabVirtualNetworkSubNetName "$DTLVNetSubnetName" -userName "$SQLUserName" -password "$SQLPassword" -ContactEmail "$LabShutdownNotificationEmail" -SQLVersionEdition "$SQLVersionEdition"
Log-Output 'Done: Creating New VM'
Log-Output "+AA++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$VMResourceGroupDeployment|Out-String|Log-Output;
Log-Output "------"
$VMResourceGroupDeployment.Outputs|Out-String|Log-Output;
Log-Output "------"
$SQLVersion = $VMResourceGroupDeployment.Outputs.sqlVersion.Value;
Log-Output ("--->VMResourceGroupDeployment.Outputs.sqlVersion:{0}" -f $SQLVersion)

$labVMId = $VMResourceGroupDeployment.Outputs.labVMId.Value;
Log-Output ("--->VMResourceGroupDeployment.Outputs.vmId:{0}" -f $labVMId)

$VmComputeId = (Get-AzResource -id $labVMId).Properties.ComputeId;
Log-Output ("--->VmComputeId:{0}" -f $VmComputeId)
Log-Output "+BB++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$ComputeRGN = (Get-AzResource -id $VmComputeId).ResourceGroupName
Log-Output ("--->ComputeRGN:{0}" -f $ComputeRGN)
Log-Output "+CC++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Log-Output "Set Tags on ResourceGroup"
Set-AzResourceGroup -Name $ComputeRGN -Tags @{"Department"="tSQLtCI";"ParentRGN"="$DTLRGName"}|Out-String|Log-Output;
Log-Output "Done: Set Tags on ResourceGroup"
Log-Output "+DD++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

##Set-PSDebug -Trace 0;


#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Log-Output "Getting VM Resource Parameters";

##(Get-AzResource -ResourceId (Get-AzResource -Name V1087sql2014sp3 -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName tSQLtCI_DevTestLab_20200323_1087_RG).ResourceId)
$DTLVm = (Get-AzResource -Name $DTLVmName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $DTLRGName);
$DTLVmWithProperties = (Get-AzResource -ResourceId $DTLVm.ResourceId);


$DTLVmWithProperties|Out-String|Log-Output;
Log-Output "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";

$DTLVmComputeId = $DTLVmWithProperties.Properties.ComputeId
$HiddenVmResourceId = $DTLVmComputeId;
Log-Output "setting variable: DTLVmComputeId:", $DTLVmComputeId

$HiddenVm = (Get-AzResource -Id $HiddenVmResourceId);
$HiddenVmRGName = $HiddenVm.ResourceGroupName
Log-Output "setting variable: HiddenVmRGName:", $HiddenVmRGName

$HiddenVmName = $DTLVmWithProperties.Name
Log-Output "setting variable: HiddenVmName:", $HiddenVmName

$labVMId = $DTLVmWithProperties.ResourceId
Log-Output 'labVMId: ', $labVMId

$HiddenVmPublicIpAddress= (Get-AzPublicIpAddress -ResourceGroupName $HiddenVmRGName -Name $HiddenVmName) ##Is this making use of an undocumented convention?
$HiddenVmFQDN = $HiddenVmPublicIpAddress.DnsSettings.Fqdn
Log-Output "setting variable: HiddenVmFQDN:", $HiddenVmFQDN

Log-Output "Adding more Tags on ResourceGroup"

$Tags = $AddTagsToResourceGroup.Invoke($DTLRGName,@{"SQLVmFQDN"="$HiddenVmFQDN";"SQLVmPort"="$SQLPort";"SQLVersionEdition"="$SQLVersionEdition";"SQLVersion"="$SQLVersion";});
$Tags|Out-String|Log-Output;

Log-Output "Done: Adding more Tags on ResourceGroup"
Log-Output 'Starting the New VM'

##Set-PSDebug -Trace 1;
Start-AzVM -Name "$HiddenVmName" -ResourceGroupName "$HiddenVmRGName"|Out-String|Log-Output;

Log-Output 'Done: Starting the New VM'
Log-Output 'Applying SqlVM Stuff'

##Set-PSDebug -Trace 1;
$SQLVM = New-AzResourceGroupDeployment -ResourceGroupName "$HiddenVmRGName" -TemplateFile "$dir\CreateSQLVirtualMachineTemplate.json" -sqlPortNumber "$SQLPort" -sqlAuthenticationLogin "$SQLUserName" -sqlAuthenticationPassword "$SQLPassword" -newVMName "$HiddenVmName" -newVMRID "$DTLVmComputeId"
$SQLVM|Out-String|Log-Output;

Log-Output 'Done: Applying SqlVM Stuff'
Log-Output 'Prep SQL Server for tSQLt Build'

$DS = Invoke-Sqlcmd -InputFile "$dir\PrepSQLServer.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword"

$DS = Invoke-Sqlcmd -InputFile "$dir\GetSQLServerVersion.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword" -As DataSet
$DS.Tables[0].Rows | %{ Log-Output "{ $($_['LoginName']), $($_['TimeStamp']), $($_['VersionDetail']), $($_['ProductVersion']), $($_['ProductLevel']), $($_['SqlVersion']) }" }

$ActualSQLVersion = $DS.Tables[0].Rows[0]['SqlVersion'];
Log-Output "Actual SQL Version:",$ActualSQLVersion;

Log-Output 'Done: Prep SQL Server for tSQLt Build';


Return @{
    "DTLRGName"="$DTLRGName";
    "DTLName"="$DTLName";
};
