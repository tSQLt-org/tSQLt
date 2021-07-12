Function Remove-ResourceGroup{
  [cmdletbinding()]
  Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ResourceGroupName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $BuildId);

  Write-Output "▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-";
  Write-Output ("[{0}]Start processing delete for {1}" -f ((get-date).toString("O")), ($ResourceGroupName));

  $MyAzResourceGroup = (Get-AzResourceGroup -name "$ResourceGroupName");
  if(("RemovalBy" -in $MyAzResourceGroup.tags.keys) -and (![string]::isnullorempty($MyAzResourceGroup.tags.RemovalBy))) {
    $MyAzResourceGroup = $null;
  }
  if($null -ne $MyAzResourceGroup) {
    $Tags = @{};
    Write-Output ("Add Tag to {0}" -f $ResourceGroupName);
    $Tags = $MyAzResourceGroup.Tags;
    $Tags.remove("RemovalBy");
    $Tags += @{"RemovalBy"="$BuildId"};
    $MyAzResourceGroup | Set-AzResourceGroup -Tags $Tags;
    Start-Sleep 10;
    Write-Output ("Confirming Tags are still in place for {0}" -f $ResourceGroupName);
    $MyAzResourceGroup = $MyAzResourceGroup | Get-AZResourceGroup | Where-Object {$_.Tags.RemovalBy -eq "$BuildId"};
    $MyAzResourceGroup.Tags | Format-Table;

    if($null -ne $MyAzResourceGroup) {
      Write-Output "Removing Locks"
      $retrievedResourceGroupName = $MyAzResourceGroup.ResourceGroupName;
      Get-AzResource -ResourceGroupName $retrievedResourceGroupName | ForEach-Object {
        Get-AzResourceLock -ResourceType $_.ResourceType -ResourceName $_.Name -ResourceGroupName $_.ResourceGroupName | ForEach-Object{
          Write-Output ("{0} -> {1}" -f $_.ResourceType, $_.ResourceName);
          $_ | Remove-AzResourceLock -Force 
        }
      }
      Write-Output ("Removing RG {0}" -f $retrievedResourceGroupName);
      $MyAzResourceGroup | Remove-AzResourceGroup -Force;
    }
    else {
      Write-Output ("Tags changed by another process. Resource Group {0} is no longer eligible to be deleted." -f $ResourceGroupName);
    }
  }        
  else {
    Write-Output ("Processing skipped for Resource Group: {0} Build Id: {1}" -f $ResourceGroupName, $BuildId);
  }
  Write-Output ("[{0}]Done processing delete for {1}" -f ((get-date).toString("O")), ($ResourceGroupName))
  Write-Output "▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-▀-▄-_-▄-";
}
