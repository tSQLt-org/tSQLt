New-Item -ItemType "directory" -Path "temp/tSQLtBuild/Facade";

../Facade/buildFacadeScripts.ps1
../FacadeTests/buildFacadeTests.ps1

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtBuild/tSQLtFacade.zip"
    }
Get-ChildItem -Path "temp/tSQLtBuild/Facade/*" -Include $facadeFiles | Compress-Archive @compress

