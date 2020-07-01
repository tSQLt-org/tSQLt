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
Write-Verbose "FileLocation: $dir"

.($dir+"\CommonFunctionsAndMethods.ps1")
Write-Verbose $GetUTCTimeStamp.Invoke()"Common Functions Imported."


Write-Verbose "<->1<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Verbose "Parameters:";
Write-Verbose "NamePreFix:" $NamePreFix;
Write-Verbose "BuildId:" $BuildId;
Write-Verbose "SQLVersionEdition:" $SQLVersionEdition;
Write-Verbose "<->2<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Verbose "Execution Environment"
Write-Verbose "UserName:"     $env:UserName
Write-Verbose "UserDomain:"   $env:UserDomain
Write-Verbose "ComputerName:" $env:ComputerName
Write-Verbose "<->3<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Verbose $GetUTCTimeStamp.Invoke();

#####################
$DTLName = ("$NamePreFix" + (Get-Date).tostring('yyyyMMdd') + "_" + $SQLVersionEdition + "_" + $BuildId)
$DTLRGName = $DTLName+'_RG'
$DTLVNetName = $DTLName+'_VNet0001'
$DTLVmName = ("V{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','')

#[string] $DTLRGName, [string] $DTLName, [string] $DTLVmName, [string] $DTLVNetName, [string] $DTLVNetSubnetName
Write-Verbose "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Verbose "Names:";
Write-Verbose "DTLRGName:" $DTLRGName;
Write-Verbose "DTLName:" $DTLName;
Write-Verbose "DTLVmName:" $DTLVmName;
Write-Verbose "DTLVNetName:" $DTLVNetName;
Write-Verbose "<->5<-><-><-><-><-><-><-><-><-><-><-><-><->";


Write-Verbose $GetUTCTimeStamp.Invoke()"Creating Resource Group $DTLRGName"
New-AzResourceGroup -Name "$DTLRGName" -Location "East US 2" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force
Write-Verbose $GetUTCTimeStamp.Invoke()"DONE: Creating Resource Group $DTLRGName"

Write-Verbose $GetUTCTimeStamp.Invoke()"Creating VNet $DTLVNetName"
$params = @{
    ResourceGroupName ="$DTLRGName";
    TemplateFile="$dir\CreateVNetTemplate.json";
    VNet_name="$DTLVNetName";
    SQL_Port="$SQLPort";
};
$VNet = New-AzResourceGroupDeployment @params;

$DTLVNetSubnetName = $VNet.Outputs.subnetName.Value
Write-Verbose "DTLVNetSubnetName:" $DTLVNetSubnetName;
Write-Verbose $GetUTCTimeStamp.Invoke()"DONE: Creating VNet $DTLVNetName"

Write-Verbose $GetUTCTimeStamp.Invoke()"Creating DTL $DTLName"
$params = @{
    ResourceGroupName="$DTLRGName";
    TemplateFile="$dir\CreateDevTestLabTemplate.json";
    newLabName="$DTLName";
    VNetName="$DTLVNetName";
    SubNetName="$DTLVNetSubnetName";
    labVmShutDownNotificationEmail="$LabShutdownNotificationEmail";
    labVmShutDownNotificationURL="$LabShutdownNotificationURL";
};
New-AzResourceGroupDeployment @params;

Write-Verbose $GetUTCTimeStamp.Invoke()"DONE: Creating DTL $DTLName"

#####################

##Set-Location $(Build.Repository.LocalPath)
Write-Verbose $GetUTCTimeStamp.Invoke()'Creating New VM'
##Set-PSDebug -Trace 1;
$VMResourceGroupDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$DTLRGName" -TemplateFile "$dir\CreateVMTemplate.json" -labName "$DTLName" -newVMName "$DTLVmName" -DevTestLabVirtualNetworkName "$DTLVNetName" -DevTestLabVirtualNetworkSubNetName "$DTLVNetSubnetName" -userName "$SQLUserName" -password "$SQLPassword" -ContactEmail "$LabShutdownNotificationEmail" -SQLVersionEdition "$SQLVersionEdition"
Write-Verbose $GetUTCTimeStamp.Invoke()'Done: Creating New VM'
Write-Verbose "+AA++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$VMResourceGroupDeployment
Write-Verbose "------"
$VMResourceGroupDeployment.Outputs
Write-Verbose "------"
$SQLVersion = $VMResourceGroupDeployment.Outputs.sqlVersion.Value;
Write-Verbose ("--->VMResourceGroupDeployment.Outputs.sqlVersion:{0}" -f $SQLVersion)

$labVMId = $VMResourceGroupDeployment.Outputs.labVMId.Value;
Write-Verbose ("--->VMResourceGroupDeployment.Outputs.vmId:{0}" -f $labVMId)

$VmComputeId = (Get-AzResource -id $labVMId).Properties.ComputeId;
Write-Verbose ("--->VmComputeId:{0}" -f $VmComputeId)
Write-Verbose "+BB++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$ComputeRGN = (Get-AzResource -id $VmComputeId).ResourceGroupName
Write-Verbose ("--->ComputeRGN:{0}" -f $ComputeRGN)
Write-Verbose "+CC++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Verbose $GetUTCTimeStamp.Invoke()"Set Tags on ResourceGroup"
Set-AzResourceGroup -Name $ComputeRGN -Tags @{"Department"="tSQLtCI";"ParentRGN"="$DTLRGName"}
Write-Verbose $GetUTCTimeStamp.Invoke()"Done: Set Tags on ResourceGroup"
Write-Verbose "+DD++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

##Set-PSDebug -Trace 0;


#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Verbose $GetUTCTimeStamp.Invoke()"Getting VM Resource Parameters";

##(Get-AzResource -ResourceId (Get-AzResource -Name V1087sql2014sp3 -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName tSQLtCI_DevTestLab_20200323_1087_RG).ResourceId)
$DTLVm = (Get-AzResource -Name $DTLVmName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $DTLRGName);
$DTLVmWithProperties = (Get-AzResource -ResourceId $DTLVm.ResourceId);


$DTLVmWithProperties;
Write-Verbose "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";

$DTLVmComputeId = $DTLVmWithProperties.Properties.ComputeId
$HiddenVmResourceId = $DTLVmComputeId;
Write-Verbose "setting variable: DTLVmComputeId:" $DTLVmComputeId

$HiddenVm = (Get-AzResource -Id $HiddenVmResourceId);
$HiddenVmRGName = $HiddenVm.ResourceGroupName
Write-Verbose "setting variable: HiddenVmRGName:" $HiddenVmRGName

$HiddenVmName = $DTLVmWithProperties.Name
Write-Verbose "setting variable: HiddenVmName:" $HiddenVmName

$labVMId = $DTLVmWithProperties.ResourceId
Write-Verbose 'labVMId: ' $labVMId

$HiddenVmPublicIpAddress= (Get-AzPublicIpAddress -ResourceGroupName $HiddenVmRGName -Name $HiddenVmName) ##Is this making use of an undocumented convention?
$HiddenVmFQDN = $HiddenVmPublicIpAddress.DnsSettings.Fqdn
Write-Verbose "setting variable: HiddenVmFQDN:" $HiddenVmFQDN

Write-Verbose $GetUTCTimeStamp.Invoke()"Adding more Tags on ResourceGroup"

$AddTagsToResourceGroup.Invoke($DTLRGName,@{"SQLVmFQDN"="$HiddenVmFQDN";"SQLVmPort"="$SQLPort";"SQLVersionEdition"="$SQLVersionEdition";"SQLVersion"="$SQLVersion";});

Write-Verbose $GetUTCTimeStamp.Invoke()"Done: Adding more Tags on ResourceGroup"
Write-Verbose $GetUTCTimeStamp.Invoke()'Starting the New VM'

##Set-PSDebug -Trace 1;
Start-AzVM -Name "$HiddenVmName" -ResourceGroupName "$HiddenVmRGName"
Set-PSDebug -Trace 0;

Write-Verbose $GetUTCTimeStamp.Invoke()'Done: Starting the New VM'
Write-Verbose $GetUTCTimeStamp.Invoke()'Applying SqlVM Stuff'

##Set-PSDebug -Trace 1;
$VM = New-AzResourceGroupDeployment -ResourceGroupName "$HiddenVmRGName" -TemplateFile "$dir\CreateSQLVirtualMachineTemplate.json" -sqlPortNumber "$SQLPort" -sqlAuthenticationLogin "$SQLUserName" -sqlAuthenticationPassword "$SQLPassword" -newVMName "$HiddenVmName" -newVMRID "$DTLVmComputeId"
Set-PSDebug -Trace 0;

Write-Verbose $GetUTCTimeStamp.Invoke()'Done: Applying SqlVM Stuff'
Write-Verbose $GetUTCTimeStamp.Invoke()'Prep SQL Server for tSQLt Build'

$DS = Invoke-Sqlcmd -InputFile "$dir\PrepSQLServer.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword"

$DS = Invoke-Sqlcmd -InputFile "$dir\GetSQLServerVersion.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword" -As DataSet
$DS.Tables[0].Rows | %{ Write-Verbose "{ $($_['LoginName']), $($_['TimeStamp']), $($_['VersionDetail']), $($_['ProductVersion']), $($_['ProductLevel']), $($_['SqlVersion']) }" }

$ActualSQLVersion = $DS.Tables[0].Rows[0]['SqlVersion'];
Write-Verbose $ActualSQLVersion;

Write-Verbose $GetUTCTimeStamp.Invoke()'Done: Prep SQL Server for tSQLt Build';


Return @{
    "DTLRGName"="$DTLRGName";
    "DTLName"="$DTLName";
};
