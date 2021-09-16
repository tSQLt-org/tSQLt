
Push-Location;

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
#Log-Output "FileLocation: $dir";
Set-Location $dir;

$createBuildDb = Get-Content "../Build/CreateBuildDb.sql";

Set-Content "../Build/temp/tSQLtBuild/Facade/CreateSourceDb.sql" $createBuildDb.Replace('$(NewDbName)', '$(FacadeSourceDb)');
Set-Content "../Build/temp/tSQLtBuild/Facade/CreateTargetDb.sql" $createBuildDb.Replace('$(NewDbName)', '$(FacadeTargetDb)');

$facadeHeader3 = 'USE $(FacadeSourceDb);'
Set-Content "../Build/temp/tSQLtBuild/Facade/FacadeHeader3.ps1" $facadeHeader3;

../Build/BuildHelper.exe "BuildOrder.txt" "../Build/temp/tSQLtBuild/Facade/FacadeScript.sql"

$executeFacadeScript = @'
    :r FacadeScript.sql
    GO
    EXEC Facade.CreateAllFacadeObjects @FacadeDbName='$(FacadeTargetDb)';
    GO
'@;

Set-Content "../Build/temp/tSQLtBuild/Facade/ExecuteFacadeScript.sql" $executeFacadeScript;

Pop-Location;