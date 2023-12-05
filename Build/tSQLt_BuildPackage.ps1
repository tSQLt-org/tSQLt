$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $invocationDir 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $OutputPath = $invocationDir + "/output/tSQLt/";
    $TempPath = $invocationDir + "/temp/tSQLt/";

    $PublicOutputPath = $OutputPath + "public/";
    $PublicTempPath = $TempPath + "public/";
    $ValidationOutputPath = $OutputPath + "validation/";
    $tSQLtDacpacPath = $PublicTempPath + "/tSQLtDacpacs/";
    $tSQLtFilesZipPath = $invocationDir + "/output/tSQLtBuild/tSQLtFiles.zip";

    $PublicOutputFiles = @(
        ($invocationDir + "/output/tSQLtBuild/ReadMe.txt"), 
        ($invocationDir + "/output/tSQLtBuild/tSQLtSnippets(SQLPrompt).zip")
    );
    $ValidationOutputFiles = @(
        ($invocationDir + "/output/tSQLtBuild/Version.txt"), 
        ($invocationDir + "/output/tSQLtBuild/CommitId.txt"), 
        ($invocationDir + "/output/tSQLtTests/tSQLt.tests.zip"), 
        ($invocationDir + "/output/tSQLtBuild/CreateBuildLog.sql"),
        ($invocationDir + "/output/tSQLtBuild/GetFriendlySQLServerVersion.sql")
    ); 

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;

    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $eatPublicOutputDir = New-Item -ItemType "directory" -Path $PublicOutputPath;
    $eattSQLtDacpacsDir = New-Item -ItemType "directory" -Path $tSQLtDacpacPath;
    $eatValidationOutputDir = New-Item -ItemType "directory" -Path $ValidationOutputPath;

    <# Copy files to temp path #>
    Expand-Archive -Path ($tSQLtFilesZipPath) -DestinationPath $PublicTempPath;
    # Get-ChildItem -Path ($dir + "/output/DacpacBuild/tSQLtFacade.*.dacpac") | Copy-Item -Destination $FacadeDacpacPath;
    Get-ChildItem -Path ($invocationDir + "/output/DacpacBuild/tSQLt.*.dacpac") | Copy-Item -Destination $tSQLtDacpacPath;

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

}
finally{
    Pop-Location
}
