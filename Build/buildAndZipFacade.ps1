# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql", "tSQLtFacade.zip");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

../Facade/buildFacadeScripts.ps1
../FacadeTests/buildFacadeTests.ps1

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtFacade.zip"
    }
Get-ChildItem -Path "output/*" -Include $facadeFiles | Compress-Archive @compress


