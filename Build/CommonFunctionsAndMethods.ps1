$MergeHashTables = {param([HashTable]$base,[HashTable]$new);$new.GetEnumerator()|%{$base.remove($_.Key);$base += @{$_.Key=$_.Value}};$base;};
$AddTagsToResourceGroup = 
{
  param([String]$ResourceGroupName,[HashTable]$newTags);
  $RG = Get-AzResourceGroup -name $ResourceGroupName;
  $RG|Set-AzResourceGroup -Tags ($MergeHashTables.Invoke($RG.Tags,$newTags)[0]);
}
$GetUTCTimeStamp = {param();(Get-Date).ToUniversalTime().ToString('[yyyy-MM-ddTHH:mm:ss.fffffff UTC]');};

Function Log-Output{[cmdletbinding()]Param([parameter(ValueFromPipeline)]$I);Process{Write-Host ([string]::Concat($GetUTCTimeStamp.Invoke()[0],[string]::Concat(" $I")));};};

Log-Output($GetUTCTimeStamp.Invoke(),"Done: Loading CommonFunctionsAndMethods");

Function Exec-SqlFileOrQuery
{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath,
    [Parameter(Mandatory=$true, ParameterSetName = 'File')][ValidateNotNullOrEmpty()][string] $FileName,
    [Parameter(Mandatory=$false, ParameterSetName = 'File')][Parameter(Mandatory=$true, ParameterSetName = 'Query')][ValidateNotNullOrEmpty()][string] $Query,
    [Parameter(Mandatory=$false)][string] $DatabaseName = "",
    [Parameter(Mandatory=$false)][string] $AdditionalParameters = ""
  );

  $DatabaseSelector = "";
  if($DatabaseName -ne ""){
    $DatabaseSelector = '-d "'+$DatabaseName+'"';
  }
  
  $ExecutionMessage = ""
  $FileNameSection = "";
  if (![string]::isnullorempty($FileName)) {
    $FileNameSection = '-i "' + $FileName + '"';
    $ExecutionMessage = $FileName;
  }
  $QuerySection = "";
  if (![string]::isnullorempty($Query)) {
    $QuerySection = '-Q "' + $Query + '"';
    $ExecutionMessage += " " + $Query;
  }
  

  $CallSqlCmd = '&"'+$SqlCmdPath+'\sqlcmd.exe" -S "'+$ServerName+'" '+$Login+' -b -I '+$FileNameSection+' '+$QuerySection+' '+$DatabaseSelector+' '+$AdditionalParameters+';';
  $CallSqlCmd = $CallSqlCmd + ';if($LASTEXITCODE -ne 0){throw "error during execution of "+$ExecutionMessage;}';

  Invoke-Expression $CallSqlCmd -ErrorAction Stop;
}