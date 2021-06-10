Push-Location;

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
#Log-Output "FileLocation: $dir";
Set-Location $dir;

../Build/BuildHelper.exe "*.class.sql" "../Build/output/FacadeTests.sql" "---Build"

$executeFacadeTests = @"
    :r FacadeScript.sql
    GO
    :r FacadeTests.sql
    GO
    EXEC tSQLt.RunAll;
    GO
"@;

Set-Content "../Build/output/ExecuteFacadeTests.sql" $executeFacadeTests;

Pop-Location;