# Delete files which might have been generated from previous builds
$filesOfInterest = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql");
Get-ChildItem -Path "output/*" -Include $filesOfInterest | Remove-Item;

../Facade/buildFacadeScripts.ps1
../FacadeTests/buildFacadeTests.ps1

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtFacade.zip"
    }
Get-ChildItem -Path "output/*" -Include $filesOfInterest | Compress-Archive @compress


