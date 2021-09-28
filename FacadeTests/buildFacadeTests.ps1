Push-Location;

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
#Log-Output "FileLocation: $dir";
Set-Location $dir;

../Build/BuildHelper.exe "*.class.sql" "../Build/temp/tSQLtBuild/Facade/FacadeTests.sql" "---Build"

$executeFacadeTests = @"
    :r FacadeScript.sql
    GO
    :r FacadeTests.sql
    GO
"@;

Set-Content "../Build/temp/tSQLtBuild/Facade/DeployFacadeTests.sql" $executeFacadeTests;

Pop-Location;