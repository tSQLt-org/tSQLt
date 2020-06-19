##$(DevTestLabRGName)
##$(DevTestLabName)
##$(vmName)
##$(DevTestLabVNetName)
##$(DevTestLabVNetSubnetName)
##${{ parameters.SQLVersion }}
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $NamePreFix,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPort,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LabVmShutdown,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LabShutdownNotificationEmail,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $LabShutdownNotificationURL,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLUserName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SQLPassword
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Write-host "FileLocation: $dir"

.($dir+"\CommonFunctionsAndMethods.ps1")
Write-host $GetUTCTimeStamp.Invoke()"Common Functions Imported."


Write-Host "<->1<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Parameters:";
Write-Host "NamePreFix:" $NamePreFix;
Write-Host "BuildId:" $BuildId;
Write-Host "SQLVersionEdition:" $SQLVersionEdition;
Write-Host "<->2<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Execution Environment"
Write-Host "UserName:"     $env:UserName
Write-Host "UserDomain:"   $env:UserDomain
Write-Host "ComputerName:" $env:ComputerName
Write-Host "<->3<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host $GetUTCTimeStamp.Invoke();

#####################
$DTLName = ("$NamePreFix" + (Get-Date).tostring(“yyyyMMdd”) + "$SQLVersionEdition" + $(Build.BuildId))
$DTLRGName = $DTLName+'_RG'
$DTLVNetName = $DTLName+'_VNet0001'
$DTLVmName = ("V{0}-{1}###############" -f $BuildId,$SQLVersionEdition).substring(0,15).replace('#','')

#[string] $DTLRGName, [string] $DTLName, [string] $DTLVmName, [string] $DTLVNetName, [string] $DTLVNetSubnetName
Write-Host "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";
Write-Host "Names:";
Write-Host "DTLRGName:" $DTLRGName;
Write-Host "DTLName:" $DTLName;
Write-Host "DTLVmName:" $DTLVmName;
Write-Host "DTLVNetName:" $DTLVNetName;
Write-Host "<->5<-><-><-><-><-><-><-><-><-><-><-><-><->";


Write-Host $GetUTCTimeStamp.Invoke()"Creating Resource Group $DTLRGName"
New-AzResourceGroup -Name "$DTLRGName" -Location "East US 2" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force
Write-Host $GetUTCTimeStamp.Invoke()"DONE: Creating Resource Group $DTLRGName"

Write-Host $GetUTCTimeStamp.Invoke()"Creating VNet $DTLVNetName"
$VNet = New-AzResourceGroupDeployment @{
    ResourceGroupName ="$DTLRGName";
    TemplateFile="$dir\CreateVNetTemplate.json";
    VNet_name="$DTLVNetName";
    SQL_Port="$SQLPort";
}

$DTLVNetSubnetName = $VNet.Outputs.subnetName.Value
Write-Host "DTLVNetSubnetName:" $DTLVNetSubnetName;
Write-Host $GetUTCTimeStamp.Invoke()"DONE: Creating VNet $DTLVNetName"

Write-Host $GetUTCTimeStamp.Invoke()"Creating DTL $DTLName"
New-AzResourceGroupDeployment @{
    ResourceGroupName="$DTLRGName";
    TemplateFile="$dir\CreateDevTestLabTemplate.json";
    newLabName="$DTLName";
    VNetName="$DTLVNetName";
    SubNetName="$DTLVNetSubnetName";
    labVmShutDownNotificationEmail="$LabShutdownNotificationEmail";
    labVmShutDownNotificationURL="$LabShutdownNotificationURL";
}
Write-Host $GetUTCTimeStamp.Invoke()"DONE: Creating DTL $DTLName"

#####################

##Set-Location $(Build.Repository.LocalPath)
Write-Host $GetUTCTimeStamp.Invoke()'Creating New VM'
##Set-PSDebug -Trace 1;
$VMResourceGroupDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$DTLRGName" -TemplateFile "$dir\CreateVMTemplate.json" -labName "$DTLName" -newVMName "$DTLVmName" -DevTestLabVirtualNetworkName "$DTLVNetName" -DevTestLabVirtualNetworkSubNetName "$DTLVNetSubnetName" -userName "$SQLUserName" -password "$SQLPassword" -ContactEmail "$LabShutdownNotificationEmail" -SQLVersionEdition "$SQLVersionEdition"
Write-Host $GetUTCTimeStamp.Invoke()'Done: Creating New VM'
Write-Host "+AA++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$VMResourceGroupDeployment
Write-Host "------"
$VMResourceGroupDeployment.Outputs
Write-Host "------"
$SQLVersion = $VMResourceGroupDeployment.Outputs.sqlVersion.Value;
Write-Host ("--->VMResourceGroupDeployment.Outputs.sqlVersion:{0}" -f $SQLVersion)

$labVMId = $VMResourceGroupDeployment.Outputs.labVMId.Value;
Write-Host ("--->VMResourceGroupDeployment.Outputs.vmId:{0}" -f $labVMId)

$VmComputeId = (Get-AzResource -id $labVMId).Properties.ComputeId;
Write-Host ("--->VmComputeId:{0}" -f $VmComputeId)
Write-Host "+BB++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$ComputeRGN = (Get-AzResource -id $VmComputeId).ResourceGroupName
Write-Host ("--->ComputeRGN:{0}" -f $ComputeRGN)
Write-Host "+CC++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Host $GetUTCTimeStamp.Invoke()"Set Tags on ResourceGroup"
Set-AzResourceGroup -Name $ComputeRGN -Tags @{"Department"="tSQLtCI";"ParentRGN"="$DTLRGName"}
Write-Host $GetUTCTimeStamp.Invoke()"Done: Set Tags on ResourceGroup"
Write-Host "+DD++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

##Set-PSDebug -Trace 0;


#$labVmId = "/subscriptions/58c04a99-5b92-410c-9e41-10262f68ca80/resourceGroups/tSQLtCI_DevTestLab_3_RG/providers/Microsoft.DevTestLab/labs/tSQLtCI_DevTestLab_3/virtualmachines/SQL2014SP3D"


Write-Host $GetUTCTimeStamp.Invoke()"Getting VM Resource Parameters";

##(Get-AzResource -ResourceId (Get-AzResource -Name V1087sql2014sp3 -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName tSQLtCI_DevTestLab_20200323_1087_RG).ResourceId)
$DTLVm = (Get-AzResource -Name $DTLVmName -ResourceType Microsoft.DevTestLab/labs/virtualmachines -ResourceGroupName $DTLRGName);
$DTLVmWithProperties = (Get-AzResource -ResourceId $DTLVm.ResourceId);


$DTLVmWithProperties;
Write-Host "<->4<-><-><-><-><-><-><-><-><-><-><-><-><->";

$DTLVmComputeId = $DTLVmWithProperties.Properties.ComputeId
$HiddenVmResourceId = $DTLVmComputeId;
Write-Host "setting variable: DTLVmComputeId:" $DTLVmComputeId
Write-Host "##vso[task.setvariable variable=DTLVmComputeId;]$DTLVmComputeId"
Write-Host "##vso[task.setvariable variable=labVmComputeId;]$DTLVmComputeId"  ##??REMOVE??
Write-Host "##vso[task.setvariable variable=HiddenVmResourceId;]$HiddenVmResourceId"

$HiddenVm = (Get-AzResource -Id $HiddenVmResourceId);
$HiddenVmRGName = $HiddenVm.ResourceGroupName
Write-Host "setting variable: HiddenVmRGName:" $HiddenVmRGName
Write-Host "##vso[task.setvariable variable=labVmRgName;]$HiddenVmRGName"  ##??REMOVE??
Write-Host "##vso[task.setvariable variable=HiddenVmRGName;]$HiddenVmRGName"

$HiddenVmName = $DTLVmWithProperties.Name
Write-Host "setting variable: HiddenVmName:" $HiddenVmName
Write-Host "##vso[task.setvariable variable=labVmName;]$HiddenVmName"  ##??REMOVE??
Write-Host "##vso[task.setvariable variable=HiddenVmName;]$HiddenVmName"

$labVMId = $DTLVmWithProperties.ResourceId
Write-Host 'labVMId: ' $labVMId
Write-Host "##vso[task.setvariable variable=labVMId;]$labVMId"

$HiddenVmPublicIpAddress= (Get-AzPublicIpAddress -ResourceGroupName $HiddenVmRGName -Name $HiddenVmName) ##Is this making use of an undocumented convention?
$HiddenVmFQDN = $HiddenVmPublicIpAddress.DnsSettings.Fqdn
Write-Host "setting variable: HiddenVmFQDN:" $HiddenVmFQDN
Write-Host "##vso[task.setvariable variable=labVMFqdn;]$HiddenVmFQDN"  ##??REMOVE??
Write-Host "##vso[task.setvariable variable=HiddenVmFQDN;]$HiddenVmFQDN"

Write-Host $GetUTCTimeStamp.Invoke()"Adding more Tags on ResourceGroup"

$AddTagsToResourceGroup.Invoke($DTLRGName,@{"SQLVmFQDN"="$HiddenVmFQDN";"SQLVmPort"="$SQLPort";"SQLVersionEdition"="$SQLVersionEdition";"SQLVersion"="$SQLVersion";});

Write-Host $GetUTCTimeStamp.Invoke()"Done: Adding more Tags on ResourceGroup"
Write-Host $GetUTCTimeStamp.Invoke()'Starting the New VM'

##Set-PSDebug -Trace 1;
Start-AzVM -Name "$HiddenVmName" -ResourceGroupName "$HiddenVmRGName"
Set-PSDebug -Trace 0;

Write-Host $GetUTCTimeStamp.Invoke()'Done: Starting the New VM'
Write-Host $GetUTCTimeStamp.Invoke()'Applying SqlVM Stuff'

##Set-PSDebug -Trace 1;
$VM = New-AzResourceGroupDeployment -ResourceGroupName "$HiddenVmRGName" -TemplateFile "$dir\CreateSQLVirtualMachineTemplate.json" -sqlPortNumber "$SQLPort" -sqlAuthenticationLogin "$SQLUserName" -sqlAuthenticationPassword "$SQLPassword" -newVMName "$HiddenVmName" -newVMRID "$DTLVmComputeId"
Set-PSDebug -Trace 0;

Write-Host $GetUTCTimeStamp.Invoke()'Done: Applying SqlVM Stuff'
Write-Host $GetUTCTimeStamp.Invoke()'Prep SQL Server for tSQLt Build'

$DS = Invoke-Sqlcmd -InputFile "$dir\PrepSQLServer.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword"

$DS = Invoke-Sqlcmd -InputFile "$dir\GetSQLServerVersion.sql" -ServerInstance "$HiddenVmFQDN,$SQLPort" -Username "$SQLUserName" -Password "$SQLPassword" -As DataSet
$DS.Tables[0].Rows | %{ echo "{ $($_['LoginName']), $($_['TimeStamp']), $($_['VersionDetail']), $($_['ProductVersion']), $($_['ProductLevel']), $($_['SqlVersion']) }" }

$ActualSQLVersion = $DS.Tables[0].Rows[0]['SqlVersion'];
Write-Host $ActualSQLVersion;

Write-Host $GetUTCTimeStamp.Invoke()'Done: Prep SQL Server for tSQLt Build'


Return @{"DTLRGName":"$DTLRGName"}