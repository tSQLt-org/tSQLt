
$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/tSQLt/";
$TempPath = $dir + "/temp/tSQLt/";
$FacadePath = $TempPath + "/Facade/";
$tSQLtFilesZipPath = $dir + "/output/tSQLtBuild/tSQLtFiles.zip";

<# Clean #>
Remove-DirectoryQuietly -Path $TempPath;
Remove-DirectoryQuietly -Path $OutputPath;

<# Init #>
$tempDir = New-Item -ItemType "directory" -Path $TempPath;
$facadeDir = New-Item -ItemType "directory" -Path $FacadePath;
$outputDir = New-Item -ItemType "directory" -Path $OutputPath;

<# Copy files to temp path #>
Expand-Archive -Path ($dir + "/output/tSQLtBuild/tSQLtFiles.zip") -DestinationPath $TempPath;
Get-ChildItem -Path ($dir + "/temp/DacpacBuild/tSQLtFacade.*.dacpac") | Copy-Item -Destination $FacadePath;

$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = $OutputPath + "/tSQLt.zip"
}
Get-ChildItem -Path $TempPath | Compress-Archive @compress
