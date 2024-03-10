using module "./CommonFunctionsAndMethods.psm1";

Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SqlServerConnection] $SqlServerConnection,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DacPacDatabaseName
);
<#
Technically this should be called by a matrixed job, so that dacpacs are built for all versions (we support, like not 2005, 2008)
#>

$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    $OutputPath = (Join-Path $invocationDir "/output/DacpacBuild/");
    $TempPath = (Join-Path $invocationDir "/temp/DacpacBuild/");

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;

    $__ = New-Item -ItemType "directory" -Path $TempPath;
    $__ = New-Item -ItemType "directory" -Path $OutputPath;

    Expand-Archive -Path (Join-Path $invocationDir "/output/tSQLtBuild/tSQLtFiles.zip"|Resolve-Path) -DestinationPath $TempPath -Force;
    Expand-Archive -Path (Join-Path $invocationDir "/output/tSQLtTests/tSQLt.tests.zip"|Resolve-Path) -DestinationPath $TempPath -Force;

    Set-Location $TempPath;
    Log-Output('Building Database')
    Log-Output('-- Executing ResetValidationServer.sql')
    Exec-SqlFile -SqlServerConnection $SqlServerConnection -FileNames @('ResetValidationServer.sql');
    Log-Output('-- Executing PrepareServer.sql')
    Exec-SqlFile -SqlServerConnection $SqlServerConnection -FileNames 'PrepareServer.sql';
    Log-Output('-- Executing CreateBuildDb.sql')
    Exec-SqlFile -SqlServerConnection $SqlServerConnection -FileNames "CreateBuildDb.sql" -Database "tempdb" -AdditionalParameters @{NewDbName=$DacPacDatabaseName} -PrintSqlOutput $true;
    Log-Output('-- Executing tSQLt.class.sql')
    Exec-SqlFile -SqlServerConnection $SqlServerConnection -FileNames "tSQLt.class.sql" -Database "$DacPacDatabaseName";
    Write-Host('Building DACPAC')
    $FriendlySQLServerVersion = Get-FriendlySQLServerVersion -SqlServerConnection $SqlServerConnection;
    $tSQLtDacpacFileName = "tSQLt."+$FriendlySQLServerVersion+".dacpac";
    $tSQLtApplicationName = "tSQLt."+$FriendlySQLServerVersion;
    $tSQLtConnectionString = $SqlServerConnection.GetConnectionString($DacPacDatabaseName,"tSQLt_BuildDacpac")
    & sqlpackage --roll-forward Major /a:Extract /scs:"$tSQLtConnectionString" /tf:"$tSQLtDacpacFileName" /p:DacApplicationName="$tSQLtApplicationName" /p:IgnoreExtendedProperties=true /p:DacMajorVersion=0 /p:DacMinorVersion=1 /p:ExtractUsageProperties=false
    if($LASTEXITCODE -ne 0) {
        throw "error during execution of dacpac " + $tSQLtDacpacFileName;
    }

    Copy-Item -Path $tSQLtDacpacFileName -Destination $OutputPath;

}
finally{
    Pop-Location
}