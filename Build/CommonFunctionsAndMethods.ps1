# $PSScriptRoot;

$MergeHashTables = {param([HashTable]$base,[HashTable]$new);$new.GetEnumerator()|%{$base.remove($_.Key);$base += @{$_.Key=$_.Value}};$base;};
$AddTagsToResourceGroup = 
{
  param([String]$ResourceGroupName,[HashTable]$newTags);
  $RG = Get-AzResourceGroup -name $ResourceGroupName;
  $RG|Set-AzResourceGroup -Tags ($MergeHashTables.Invoke($RG.Tags,$newTags)[0]);
}
$GetUTCTimeStamp = {param();(Get-Date).ToUniversalTime().ToString('[yyyy-MM-ddTHH:mm:ss.fffffff UTC]');};
$SQLPrintCurrentTime = "EXEC('DECLARE @C VARCHAR(MAX)=CONVERT(VARCHAR(MAX),SYSUTCDATETIME(),127);RAISERROR(@C,0,1)WITH NOWAIT;');";

Function Log-Output{[cmdletbinding()]Param([parameter(ValueFromPipeline)]$I);Process{Write-Host ([string]::Concat($GetUTCTimeStamp.Invoke()[0],[string]::Concat(" $I")));};};

Log-Output($GetUTCTimeStamp.Invoke(),"Done: Loading CommonFunctionsAndMethods");

Function Exec-SqlFileOrQuery
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
      [string] $ServerName,
    
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
      [string] $Login,
    
    [Parameter(Mandatory=$true, ParameterSetName = 'File')][ValidateNotNullOrEmpty()]
      [string[]] $FileNames,
    
    [Parameter(Mandatory=$false, ParameterSetName = 'File')]
    [Parameter(Mandatory=$true, ParameterSetName = 'Query')][ValidateNotNullOrEmpty()]
      [string] $Query,
    
    [Parameter(Mandatory=$false)]
      [string] $DatabaseName = "",
    
    [Parameter(Mandatory=$false)]
      [string] $AdditionalParameters = ""
  );

  $DatabaseSelector = "";
  if($DatabaseName -ne ""){
    $DatabaseSelector = '-d "'+$DatabaseName+'"';
  }
  
  $ExecutionMessage = ""
  $FileNameSection = "";
  <# -i input_file[,input_file2...] #>
  if (![string]::isnullorempty($FileNames)) {
    $FileNameSection = '-i "'+($FileNames -Join '" -i "')+'"';
    $ExecutionMessage = $FileNames;
  }
  $QuerySection = "";
  if (![string]::isnullorempty($Query)) {
    $Query = $SQLPrintCurrentTime+$Query+$SQLPrintCurrentTime
    $QuerySection = '-Q "' + $Query + '"';
    $ExecutionMessage += " " + $Query;
  }
  

  $CallSqlCmd = '& "sqlcmd" -S "'+$ServerName+'" '+$Login+' -b -I '+$FileNameSection+' '+$QuerySection+' '+$DatabaseSelector+' '+$AdditionalParameters+';';
  $CallSqlCmd = 'Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff";'+$CallSqlCmd+'Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff";'
  $CallSqlCmd = $CallSqlCmd + ';if($LASTEXITCODE -ne 0){throw "error during execution of "+$ExecutionMessage;}';
  # $CallSqlCmd
  $dddbefore = Get-Date;Write-Warning("------->>BEFORE<<-------(CommonFunctionsAndMethods.p1:Exec-SqlFileOrQuery:Invoke-Expression[$($dddbefore|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
  Invoke-Expression $CallSqlCmd -ErrorAction Stop;
  $dddafter = Get-Date;Write-Warning("------->>After<<-------(CommonFunctionsAndMethods.p1:Exec-SqlFileOrQuery:Invoke-Expression[$($dddafter|Get-Date -Format "yyyy:MM:dd;HH:mm:ss.fff")])")
  # $dddafter-$dddbefore
}

Function Get-SqlConnectionString
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName
  );

  $ServerNameTrimmed = $ServerName.Trim();
  $LoginTrimmed = $Login.Trim();

  <# 
    ☹️
    This is so questionable, but it looks like sqlpackage cannot handle valid connection strings that use a valid server alias.
    The following snippet is meant to spelunk through the registry and extract the actual server from the alias.
    ☹️
  #>
  $resolvedServerName = $ServerNameTrimmed;
  $serverAlias = Get-Item -Path HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo -ErrorAction SilentlyContinue;
  if ($null -ne $serverAlias -And $serverAlias.GetValueNames() -contains $ServerNameTrimmed) {
      $aliasValue = $serverAlias.GetValue($ServerNameTrimmed)
      if ($aliasValue -match "DBMSSOCN[,](.*)"){
          $resolvedServerName = $Matches[1];
      }
  }
  
  <# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
  if ($LoginTrimmed -match '((.*[-][uU])|(.*[-][pP]))+.*'){
      $AuthenticationString = $LoginTrimmed -replace '^((\s*[-][uU]\s+(?<user>\S+)\s*)|(\s*[-][pP]\s+)((?<quote>[''"])(?<password>.*?)\k<quote>|(?<password>\S+))\s*)+$', 'User Id=${user};Password="${password}"'  
  }
  elseif ($LoginTrimmed -eq "-E"){
      $AuthenticationString = "Integrated Security=SSPI;";
  }
  else{
      throw $LoginTrimmed + " is not supported here."
  }

  $SqlConnectionString = "Data Source="+$resolvedServerName+";"+$AuthenticationString+";Connect Timeout=60;Initial Catalog="+$DatabaseName+";TrustServerCertificate=true;";
  $SqlConnectionString;
}

function Get-FriendlySQLServerVersion {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$false)][switch]$Quiet
  )
  $ServerNameTrimmed = $ServerName.Trim();
  $LoginTrimmed = $Login.Trim();

  $GetFriendlySQLServerVersionFullPath = (Get-ChildItem -Path ($PSScriptRoot + '/output/*') -include "GetFriendlySQLServerVersion.sql" -Recurse | Select-Object -First 1 ).FullName;
  $GetFriendlySQLServerVersionStatement = (Get-Content -Path $GetFriendlySQLServerVersionFullPath).Replace([System.Environment]::NewLine,' ');
  $resultSet = Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -Query "$GetFriendlySQLServerVersionStatement" -DatabaseName 'tempdb';
  if(!$Quiet){Log-Output "Friendly SQL Server Version: $resultSet"};
  $resultSet.Trim();
}

function Update-Archive {
  param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $ArchiveName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String[]] $FileNamesToInclude
  )
  <# Create directory to unpack compressed file #>
  $ArchiveDirectory = $ArchiveName + "." + (Get-Date -Format "yyyy-MM-dd-HHmm");
  New-Item -ItemType Directory -Path ".\$ArchiveDirectory";

  <# Unpack compressed file into newly created directory #>
  Expand-Archive -LiteralPath $ArchiveName -DestinationPath $ArchiveDirectory;

  <# Rename original archive file #>
  $NewArchiveName = $ArchiveName + ".original";
  Rename-Item -Path $ArchiveName -NewName $NewArchiveName;

  <# Copy new files to include into the archive directory #>
  foreach ($FileName in $FileNamesToInclude) {
    Copy-Item $FileName -Destination $ArchiveDirectory;    
  }

  <# Compress files #>
  $compress = @{
    Path = $ArchiveDirectory
    CompressionLevel = "Fastest"
    DestinationPath = $ArchiveName
    }
  Compress-Archive @compress
}

function Remove-DirectoryQuietly {
  param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $Path
  )
  if (Test-Path -Path $Path) {
    Remove-Item -Path $Path -Recurse -Force
  }
}

Function Remove-ResourceGroup{
  [CmdletBinding()]
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

Function Get-SnipContent {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][AllowEmptyString()][string[]]$searchArray,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $startSnipPattern,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String] $endSnipPattern
  )
  begin {
    $outputOn = $false;
  };
  process {
    $searchArray | ForEach-Object {
      if($_ -eq $endSnipPattern) { $outputOn = $false };
      if($outputOn) { $_ };
      if($_ -eq $startSnipPattern) { $outputOn = $true };
    }
  };
  end {
  };
}

Function Replace-InFile {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][AllowEmptyString()][string[]]$filePath,
    [Parameter(Mandatory=$true)][array] $replacements
  )
  begin {
  };
  process {
    $fileContent = (Get-Content -Path $filePath)
    $replacements|ForEach-Object{
      $sv = $_[0]
      $rv=$_[1]; 
      $isRegex = $false;
      if($rv -is [array]){
        $isRegex = $true
        $rv = $rv[0]
      }
      Write-Host("Replacing >$_< with >$rv<...");
      if($isRegex){
        $fileContent = $fileContent -replace $_, $rv 
      }else{
        $fileContent = $fileContent.Replace($_, $rv) 
      }
    }
    $fileContent | Set-Content -Path $releaseNotesPath
  };
  end {
  };
}
