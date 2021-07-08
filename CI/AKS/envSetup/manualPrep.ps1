Param(
    [Parameter(Mandatory=$true,HelpMessage="projectName must be at least of length 3 no more than 50 and can contain only alphanumeric characters ([a-z], [A-Z], [0-9]) or underscores (_). Spaces are not allowed.")]
    [ValidatePattern("^[0-9a-zA-Z_]{3,50}$")]
    [string] $projectName  = "db_actions",
    [string] $subscriptionId = "default"
);

# Make sure that the projectName parameter does not include characters not allowed in the GitHub Secrets names
# As of 2021-01-24, "Secret names can only contain alphanumeric characters ([a-z], [A-Z], [0-9]) or underscores (_). Spaces are not allowed."

if($subscriptionId -ne "default") {
    az account set $subscriptionId;
}

$azSubscriptionId = az account show --query id -o tsv;

Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   BASE64 SNIPPET  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
Write-Output ("Deploying to Subscription Id: {0}" -f $azSubscriptionId);
Write-Output "💖";
Write-Output "💖";
Write-Output "Continuing in...";
for ($i = 5; $i -gt 0; $i--){
    Write-Output "✨ $i ✨";
    Start-Sleep -Seconds 1;
}
$region = "eastus2"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

# Create the resource group
az group create -l $region -n $azResourceGroupName

# Ensure the resource group Provisioning State is Suceeded. For example:
$sleepInterval = 10;
$waitTimeLimit = 0;
while ("Succeeded" -ne (az group list --query "[?name=='$azResourceGroupName'].{provisioningState: properties.provisioningState}" -o tsv)) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
    if($waitTimeLimit -ge 60){
        throw "Something catastrophic has happened! The expected provisioning state was not found after $waitTimeLimit seconds.";
    }

}

# Create the service principal. The contributor role is insufficient for attaching a newly created ACR to an AKS cluster.
# We must check that the clientSecret does not contain single or double quotes.
# If it does, the either the json snippet returned will be invalid (in the case of the double quote)
# or it will break AKS later down the line (in the case of the single quote).
Do {
    Write-Output "Generating Credentials";
    $spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId";
} While (
    ($spCredential.Split("`r`n").Split("`r").Split("`n") | Where-Object { $_ -match "^\s*`"clientSecret`"\s*:\s*`"[^`"]*[`"'][^`"]*`"\s*,?\s*$" }).count -gt 0
);

$spCredential;

Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   BASE64 SNIPPET  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($spCredential));
Write-Output "💖";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "";
Write-Output "";
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   INSTRUCTIONS  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
Write-Output "💖   Copy the base64 encoded snippet above and save it as the GitHub Secret `"AZ_SP_CRED_$projectName`"."; 
Write-Output "💖";
Write-Output "💖   GitHub secrets can be set by going to Settings > Secrets > `"New repository secret`".";
Write-Output "💖";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";

$serviceProviders = 'Microsoft.KeyVault', 'Microsoft.Kubernetes', 'Microsoft.ContainerRegistry', 'Microsoft.ContainerService';

# Register required services
foreach ($item in $serviceProviders) {
    az provider register --namespace $item;
}

# Wait until all required services are registered.
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖   Waiting for registration of service providers."; 
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
$waitTimeLimit = 0;
while ((az provider list --query ("[?contains('", ($serviceProviders -join '|'), "',namespace)].{registrationState: registrationState}" -join "") -o tsv) -join "" -ne "Registered" * $serviceProviders.count) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
    if($waitTimeLimit -ge 300){
        throw "Something catastrophic has happened! The expected registration states were not found after $waitTimeLimit seconds.";
    }
}
