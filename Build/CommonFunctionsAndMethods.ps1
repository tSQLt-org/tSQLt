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

Function Get-SqlConnectionString
{
  [cmdletbinding()]
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
  $serverAlias = Get-Item -Path HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo;
  if ($serverAlias.GetValueNames() -contains $ServerNameTrimmed) {
      $aliasValue = $serverAlias.GetValue($ServerNameTrimmed)
      if ($aliasValue -match "DBMSSOCN[,](.*)"){
          $resolvedServerName = $Matches[1];
      }
  }
  
  <# When using Windows Authentication, you must use "Integrated Security=SSPI" in the SqlConnectionString. Else use "User ID=<username>;Password=<password>;" #>
  if ($LoginTrimmed -match '((.*[-]U)|(.*[-]P))+.*'){
      $AuthenticationString = $LoginTrimmed -replace '^((\s*([-]U\s+)(?<user>\w+)\s*)|(\s*([-]P\s+)(?<password>\S+)\s*))+$', 'User Id=${user};Password="${password}"'  
  }
  elseif ($LoginTrimmed -eq "-E"){
      $AuthenticationString = "Integrated Security=SSPI;";
  }
  else{
      throw $LoginTrimmed + " is not supported here."
  }

  $SqlConnectionString = "Data Source="+$resolvedServerName+";"+$AuthenticationString+";Connect Timeout=60;Initial Catalog="+$DatabaseName;
  $SqlConnectionString;
}

function Get-FriendlySQLServerVersion {
  param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath
  )
  $ServerNameTrimmed = $ServerName.Trim();
  $LoginTrimmed = $Login.Trim();

  $QueryString = "DECLARE @FriendlyVersion NVARCHAR(128) = (SELECT FriendlyVersion FROM tSQLt.FriendlySQLServerVersion(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)))); PRINT @FriendlyVersion;";
  $resultSet = Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -SqlCmdPath $SqlCmdPath -Query $QueryString -DatabaseName $DatabaseName;
  Log-Output "Friendly SQL Server Version: $resultSet";
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
