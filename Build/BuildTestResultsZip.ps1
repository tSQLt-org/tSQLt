
$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/Validate/";
$TempPath = $dir + "/temp/Validate/";
$TestResultsZipPath = $OutputPath + "TestResults.zip";

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = $TestResultsZipPath
}
Get-ChildItem -Path ($TempPath + "TestResults*.xml") -Recurse | Compress-Archive @compress
