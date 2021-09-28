New-Item -ItemType "directory" -Path "temp/tSQLtBuild/Facade";

../Facade/buildFacadeScripts.ps1
../FacadeTests/buildFacadeTests.ps1

$fileList = @("PrepareServer.sql","ResetValidationServer.sql");
$tempPath = "temp/tSQLtBuild/Facade/";

Copy-Item -Path "temp/tSQLtBuild/*" -Include $fileList -Destination $tempPath;

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtBuild/tSQLtFacade.zip"
    }
Get-ChildItem -Path $tempPath | Compress-Archive @compress

