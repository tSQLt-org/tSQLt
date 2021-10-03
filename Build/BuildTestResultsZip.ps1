Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ResultFiles
);

$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/Validate/";
$TempPath = $dir + "/temp/Validate/";
$TestResultsZipPath = $OutputPath + "TestResults.zip";
$ExpectedTestResultFileNames = $ResultFiles.Split(';');

$ActualTestResultFiles = Get-ChildItem -Path $TempPath -Include "TestResults*.xml" -Recurse;

if ($null -eq $ActualTestResultFiles) {
    throw "ActualTestResultsFiles is null."
}
$ActualTestResultFileNames = $ActualTestResultFiles.Name;

$compare = Compare-Object -ReferenceObject $ExpectedTestResultFileNames -DifferenceObject $ActualTestResultFileNames -PassThru;

if ($compare.length -ne 0) {
    $throwMessage = @"
Expected files:   $ExpectedTestResultFileNames

Actual files: $ActualTestResultFileNames

Unexpected or missing files: $compare

"@;
    $throwMessage;
    throw "There were missing or unexpected files."
}

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = $TestResultsZipPath
}
Get-ChildItem -Path ($TempPath + "TestResults*.xml") -Recurse | Compress-Archive @compress
