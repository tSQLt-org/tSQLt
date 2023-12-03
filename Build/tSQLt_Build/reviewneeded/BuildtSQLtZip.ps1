
$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;

.($dir+"\CommonFunctionsAndMethods.ps1");

$OutputPath = $dir + "/output/tSQLt/";
$TempPath = $dir + "/temp/tSQLt/";
$PublicOutputPath = $OutputPath + "public/";
$PublicTempPath = $TempPath + "public/";
$ValidationOutputPath = $OutputPath + "validation/";
$FacadeDacpacPath = $PublicTempPath + "/FacadeDacpacs/";
$tSQLtDacpacPath = $PublicTempPath + "/tSQLtDacpacs/";
$tSQLtFilesZipPath = $dir + "/output/tSQLtBuild/tSQLtFiles.zip";
$PublicOutputFiles = @(
    ($dir + "/output/tSQLtBuild/ReadMe.txt"), 
    ($dir + "/output/tSQLtBuild/tSQLtSnippets(SQLPrompt).zip")
);
$ValidationOutputFiles = @(
    ($dir + "/output/tSQLtBuild/Version.txt"), 
    ($dir + "/output/tSQLtBuild/CommitId.txt"), 
    ($dir + "/output/tSQLtBuild/tSQLt.tests.zip"), 
    ($dir + "/output/tSQLtBuild/tSQLtFacade.zip"),
    ($dir + "/output/tSQLtBuild/CreateBuildLog.sql"),
    ($dir + "/output/tSQLtBuild/GetFriendlySQLServerVersion.sql")
); 

<# Clean #>
Remove-DirectoryQuietly -Path $TempPath;
Remove-DirectoryQuietly -Path $OutputPath;

<# Init directories, capturing the return values in a variable so that they don't print. #>
$eatPublicOutputDir = New-Item -ItemType "directory" -Path $PublicOutputPath;
$eatFacadeDacpacsDir = New-Item -ItemType "directory" -Path $FacadeDacpacPath;
$eattSQLtDacpacsDir = New-Item -ItemType "directory" -Path $tSQLtDacpacPath;
$eatValidationOutputDir = New-Item -ItemType "directory" -Path $ValidationOutputPath;

<# Copy files to temp path #>
Expand-Archive -Path ($tSQLtFilesZipPath) -DestinationPath $PublicTempPath;
Get-ChildItem -Path ($dir + "/output/DacpacBuild/tSQLtFacade.*.dacpac") | Copy-Item -Destination $FacadeDacpacPath;
Get-ChildItem -Path ($dir + "/output/DacpacBuild/tSQLt.*.dacpac") | Copy-Item -Destination $tSQLtDacpacPath;

<# Create the tSQLt.zip in the public output path #>
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = $PublicOutputPath + "/tSQLt.zip"
}
Get-ChildItem -Path $PublicTempPath | Compress-Archive @compress

<# Copy all public files into public output path #>
Copy-Item -Path $PublicOutputFiles -Destination $PublicOutputPath

<# Copy all validation files into validation output path #>
Copy-Item -Path $ValidationOutputFiles -Destination $ValidationOutputPath


