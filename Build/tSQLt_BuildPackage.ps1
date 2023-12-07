$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $invocationDir 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $OutputPath = (Join-Path $invocationDir "/output/tSQLt/");
    $TempPath = (Join-Path $invocationDir "/temp/tSQLt/");

    $PublicOutputPath = (Join-Path $OutputPath "public/");
    $PublicTempPath = (Join-Path $TempPath "public/");
    $ValidationOutputPath = (Join-Path $OutputPath "validation/");
    $tSQLtDacpacPath = (Join-Path $PublicTempPath "tSQLtDacpacs/");
    
    $tSQLtFilesZipSourcePath = (Join-Path $invocationDir "/output/tSQLtBuild/tSQLtFiles.zip" | Resolve-Path);
    $tSQLtDacpacSourcePath = (Join-Path $invocationDir "/output/DacpacBuild" | Resolve-Path);

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
    $__ = New-Item -ItemType "directory" -Path $PublicOutputPath;
    $__ = New-Item -ItemType "directory" -Path $tSQLtDacpacPath;
    $__ = New-Item -ItemType "directory" -Path $ValidationOutputPath;

    <# Copy files to temp path #>
    Expand-Archive -Path ($tSQLtFilesZipSourcePath) -DestinationPath $PublicTempPath;
    # Get-ChildItem -Path ($dir + "/output/DacpacBuild/tSQLtFacade.*.dacpac") | Copy-Item -Destination $FacadeDacpacPath;
    Get-ChildItem -Path ($tSQLtDacpacSourcePath) -Filter 'tSQLt.*.dacpac' | Copy-Item -Destination $tSQLtDacpacPath;

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
