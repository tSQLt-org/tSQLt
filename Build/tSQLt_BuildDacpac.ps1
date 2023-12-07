Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login
);
<#
Technically this should be called by a matrixed job, so that dacpacs are built for all versions (we support, like not 2005, 2008)
#>
$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $PSScriptRoot 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $OutputPath = (Join-Path $invocationDir "/output/DacpacBuild/");
    $TempPath = (Join-Path $invocationDir "/temp/DacpacBuild/");

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;

    $__ = New-Item -ItemType "directory" -Path $TempPath;
    $__ = New-Item -ItemType "directory" -Path $OutputPath;

    Expand-Archive -Path (Join-Path $invocationDir "/output/tSQLtBuild/tSQLtFiles.zip"|Resolve-Path) -DestinationPath $TempPath -Force;
    Expand-Archive -Path (Join-Path $invocationDir "/output/tSQLtTests/tSQLt.tests.zip"|Resolve-Path) -DestinationPath $TempPath -Force;

    $ServerNameTrimmed = $ServerName.Trim();
    $LoginTrimmed = $Login.Trim("'").Trim();

    Set-Location $TempPath;
    Log-Output('Building Database')
    Log-Output('-- Executing ResetValidationServer.sql')
    Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -FileNames 'ResetValidationServer.sql';
    Log-Output('-- Executing PrepareServer.sql')
    Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -FileNames 'PrepareServer.sql';
    Log-Output('-- Executing CreateBuildDb.sql')
    Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -FileNames "CreateBuildDb.sql" -Database "tempdb" -AdditionalParameters ('-v NewDbName="'+$DatabaseName+'"');
    Log-Output('-- Executing tSQLt.class.sql')
    Exec-SqlFileOrQuery -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -FileNames "tSQLt.class.sql" -Database "$DatabaseName";
    Write-Host('Building DACPAC')
    $FriendlySQLServerVersion = Get-FriendlySQLServerVersion -ServerName $ServerNameTrimmed -Login "$LoginTrimmed";
    $tSQLtDacpacFileName = "tSQLt."+$FriendlySQLServerVersion+".dacpac";
    $tSQLtApplicationName = "tSQLt."+$FriendlySQLServerVersion;
    $tSQLtConnectionString = Get-SqlConnectionString -ServerName $ServerNameTrimmed -Login "$LoginTrimmed" -DatabaseName $DatabaseName;
# $tSQLtConnectionString
    & sqlpackage --roll-forward Major /a:Extract /scs:"$tSQLtConnectionString" /tf:"$tSQLtDacpacFileName" /p:DacApplicationName="$tSQLtApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
    if($LASTEXITCODE -ne 0) {
        throw "error during execution of dacpac " + $tSQLtDacpacFileName;
    }

    Copy-Item -Path $tSQLtDacpacFileName -Destination $OutputPath;

}
finally{
    Pop-Location
}