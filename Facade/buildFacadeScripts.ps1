
Push-Location;

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
#Log-Output "FileLocation: $dir";
Set-Location $dir;

$createBuildDb = Get-Content "../Build/CreateBuildDb.sql";

Set-Content "../Build/temp/CreateSourceDb.sql" $createBuildDb.Replace('$(NewDbName)', '$(FacadeSourceDb)');
Set-Content "../Build/temp/CreateTargetDb.sql" $createBuildDb.Replace('$(NewDbName)', '$(FacadeTargetDb)');

$facadeHeader3 = 'USE $(FacadeSourceDb);'
Set-Content "../Build/temp/FacadeHeader3.ps1" $facadeHeader3;

../Build/BuildHelper.exe "BuildOrder.txt" "../Build/output/FacadeScript.sql"

$executeFacadeScript = @'
    :r FacadeScript.sql
    GO
    EXEC Facade.CreateAllFacadeObjects @FacadeDbName='$(FacadeTargetDb)';
    GO
'@;

Set-Content "../Build/output/ExecuteFacadeScript.sql" $executeFacadeScript;

Pop-Location;