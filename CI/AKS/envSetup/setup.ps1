Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $projectName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $azServicePrincipalCredentials,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $sshPassphrase,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $linuxNodePoolDefaultVMSize,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $windowsNodePoolDefaultVMSize,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $kubernetesVersion,
    [Parameter(Mandatory=$false)][Switch] $debugOn
);

# https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/
function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

function Get-MD5HashOfString($string) {
    $stringAsStream = [System.IO.MemoryStream]::new();
    $writer = [System.IO.StreamWriter]::new($stringAsStream);
    $writer.write($string);
    $writer.Flush();
    $stringAsStream.Position = 0;
    $hashedString = (Get-FileHash -InputStream $stringAsStream).Hash;
    return [String]$hashedString;
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
if ($debugOn) {
    $DebugPreference = "Continue"
}

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug "";
Write-Debug ("ErrorActionPreference: {0}" -f "$ErrorActionPreference"); 
Write-Debug "";
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

$azResourceGroupName = "rg_" + $projectName;
$region = (Get-AzResourceGroup -Name $azResourceGroupName).Location
$projectNameHash = (Get-MD5HashOfString($projectName)).Substring(0,10);
$azSecretsManagerName = "sm-" + $projectNameHash;
$aksClusterName = "aks-" + $projectNameHash;
$containerRegistryName = ("crn-" + $projectNameHash).Replace('-','');
$aksWinUser = ("aksWinUser-" + $projectNameHash).Replace('-','');
$aksWinNodePoolName = "akswin"; #What can I name my Windows node pools? You have to keep the name to a maximum of 6 (six) characters. This is a current limitation of AKS. (https://docs.microsoft.com/en-us/azure/aks/windows-faq)

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("Project Name: {0}" -f "$projectName"); 
Write-Debug ("Region: {0}" -f "$region"); 
Write-Debug ("Resource Group Name: {0}" -f "$azResourceGroupName"); 
Write-Debug ("Secrets Manager Name: {0}" -f "$azSecretsManagerName"); 
Write-Debug ("AKS Cluster Name: {0}" -f "$aksClusterName"); 
Write-Debug ("Container Registry Name: {0}" -f "$containerRegistryName"); 
Write-Debug ("AKS Win User Name: {0}" -f "$aksWinUser"); 
Write-Debug ("AKS Win Node Pool Name: {0}" -f "$aksWinNodePoolName"); 
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

# Parse service principal credentials to extract the subscription id and client secret.
$convertedCredentials = (ConvertFrom-Json $azServicePrincipalCredentials)
$azServicePrincipalClientId = $convertedCredentials.clientId;
$azSubscriptionId = $convertedCredentials.subscriptionId;
$azServicePrincipalClientSecret = $convertedCredentials.clientSecret;

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("✨   azServicePrincipalClientId: {0}" -f "$azServicePrincipalClientId"); 
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

$azServicePrincipalObjectId = (Get-AzADServicePrincipal -ApplicationId $azServicePrincipalClientId).Id

# Set up Secrets Manager on Azure (AKV). If the AKV exists, throws a non-terminating error.
# This fails miserably if there exists a AKV soft-deleted in the same region with the same name. I don't see a way to turn off soft-delete. So if one exists, it requires manual intervention. Turns out that the minimim SoftDeleteRetentionInDays is the magic number 7.
New-AzKeyVault -VaultName "$azSecretsManagerName" -ResourceGroupName "$azResourceGroupName" -Location "$region" -SoftDeleteRetentionInDays 7

# TODO: 

# The Azure Key Vault RBAC is two separate levels, management and data. The Contributor role assigned above to the azure service principal as part of manualPrep.ps1 is for the management level. Additional permissions are required to manipulate the data level. (https://docs.microsoft.com/en-us/azure/key-vault/general/overview-security)
Set-AzKeyVaultAccessPolicy -VaultName "$azSecretsManagerName" -ResourceGroupName "$azResourceGroupName" -ObjectId $azServicePrincipalObjectId -PermissionsToSecrets Get,Set

# ^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%\^&\*\(\)])[a-zA-Z\d!@#$%\^&\*\(\)]***12,123***$
$part1 = (Get-RandomCharacters -length 10 -characters 'abcdefghiklmnoprstuvwxyz');
$part2 = (Get-RandomCharacters -length 10 -characters '1234567890');
$part3 = (Get-RandomCharacters -length 10 -characters 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
$part4 = (Get-RandomCharacters -length 10 -characters '!#$%^&*');
$allParts = -join ((-join ($part1,$part2,$part3,$part4)).ToCharArray() | Get-Random -Shuffle)
$aksPassword = ConvertTo-SecureString -String "$allParts" -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksPassword' -SecretValue $aksPassword;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'projectName' -SecretValue (ConvertTo-SecureString -String $projectName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'region' -SecretValue (ConvertTo-SecureString -String $region -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azResourceGroupName' -SecretValue (ConvertTo-SecureString -String $azResourceGroupName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azSecretsManagerName' -SecretValue (ConvertTo-SecureString -String $azSecretsManagerName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksClusterName' -SecretValue (ConvertTo-SecureString -String $aksClusterName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'containerRegistryName' -SecretValue (ConvertTo-SecureString -String $containerRegistryName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinUser' -SecretValue (ConvertTo-SecureString -String $aksWinUser -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinNodePoolName' -SecretValue (ConvertTo-SecureString -String $aksWinNodePoolName -AsPlainText -Force);

# Create a Container Registry. If the ACR exists, throws a non-terminating error.
New-AzContainerRegistry -ResourceGroupName "$azResourceGroupName" -Name "$containerRegistryName" -Sku "Basic"

# Suppress irritating warnings about breaking changes in New-AzAksCluster, "WARNING: Upcoming breaking changes in the cmdlet 'New-AzAksCluster' :The cmdlet 'New-AzAksCluster' is replacing this cmdlet. - The parameter : 'NodeVmSetType' is changing. - Change description : Default value will be changed from AvailabilitySet to VirtualMachineScaleSets. - The parameter : 'NetworkPlugin' is changing. - Change description : Default value will be changed from None to azure."
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

$azServicePrincipalCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($azServicePrincipalClientId, (ConvertTo-SecureString -String $azServicePrincipalClientSecret -AsPlainText -Force));

# Set up ssh key pair (https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)
ssh-keygen -m PEM -t rsa -b 4096 -f ~/.ssh/id_rsa -N "$sshPassphrase"

# Create "~/.azure/acsServicePrincipal.json" with the format {"$azSubscriptionId":{"service_principal":"$azServicePrincipalClientId","client_secret":"$azServicePrincipalClientSecret"}}
$fileContent = ('{"', $azSubscriptionId, '":{"service_principal":"', $azServicePrincipalClientId, '","client_secret":"', $azServicePrincipalClientSecret, '"}}' -join "");
Set-Content -Path ~/.azure/acsServicePrincipal.json -Value $fileContent;

# Create a new AKS Cluster with a single linux node
# TODO: Figure out if we can create a .json file for the service principal a la https://github.com/Azu re/azure-powershell/issues/13012 
New-AzAksCluster -ServicePrincipalIdAndSecret $azServicePrincipalCreds -ResourceGroupName "$azResourceGroupName" -Name "$aksClusterName" -NodeCount 1 -NetworkPlugin azure -NodeVmSetType VirtualMachineScaleSets -WindowsProfileAdminUserName "$aksWinUser" -WindowsProfileAdminUserPassword $aksPassword -KubernetesVersion "$kubernetesVersion" -NodeVmSize $linuxNodePoolDefaultVMSize;

# Add a Windows Server node pool to our existing cluster
New-AzAksNodePool -ResourceGroupName "$azResourceGroupName" -ClusterName "$aksClusterName" -OsType Windows -Name "$aksWinNodePoolName" -VMSetType VirtualMachineScaleSets -Count 1 -KubernetesVersion "$kubernetesVersion" -VmSize $windowsNodePoolDefaultVMSize;

$containerRegistryURL = "$containerRegistryName.azurecr.io";
az aks get-credentials --resource-group "$azResourceGroupName" --name "$aksClusterName"
kubectl create secret docker-registry acr-secret --docker-server="$containerRegistryURL" --docker-username="$azServicePrincipalClientId" --docker-password="$azServicePrincipalClientSecret"
