$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/DacpacBuild/";
$TempPath = $dir + "/temp/DacpacBuild/";

<# Clean #>
Remove-DirectoryQuietly -Path $TempPath;
Remove-DirectoryQuietly -Path $OutputPath;

$tempDir = New-Item -ItemType "directory" -Path $TempPath;
$outputDir = New-Item -ItemType "directory" -Path $OutputPath;


Expand-Archive -Path ($dir + "/output/tSQLtBuild/tSQLtFacade.zip") -DestinationPath $TempPath;
Expand-Archive -Path ($dir + "/output/tSQLtBuild/tSQLtFiles.zip") -DestinationPath $TempPath -Force;
