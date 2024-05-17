using module "./CommonFunctionsAndMethods.psm1";

$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    $tSQLtBuildPath = (Join-Path $invocationDir '/output/tSQLtBuild/'|Resolve-Path);
    $tSQLtTestsPath = (Join-Path $invocationDir '/output/tSQLtTests/'|Resolve-Path);
    $DacpacBuildPath = (Join-Path $invocationDir '/output/DacpacBuild/'|Resolve-Path);
    # Write-Warning "BuildPackage Inputs:"
    # Write-Warning "----------------------------------------------------------------"
    # Get-ChildItem $tSQLtBuildPath -Recurse |FT;
    # Write-Warning "----------------------------------------------------------------"
    # Get-ChildItem $tSQLtTestsPath -Recurse |FT;
    # Write-Warning "----------------------------------------------------------------"
    # Get-ChildItem $DacpacBuildPath -Recurse |FT;
    # Write-Warning "----------------------------------------------------------------"

    $OutputPath = (Join-Path $invocationDir "/output/tSQLt/");
    $TempPath = (Join-Path $invocationDir "/temp/tSQLt/");

    $PublicOutputPath = (Join-Path $OutputPath "public/");
    $PublicTempPath = (Join-Path $TempPath "public/");
    $ValidationOutputPath = (Join-Path $OutputPath "validation/");
    $tSQLtDacpacPath = (Join-Path $PublicTempPath "tSQLtDacpacs/");
    $SourcePath = (Join-Path $TempPath "Source/");
    $DacpacSourcePath = (Join-Path $SourcePath "Dacpacs/");
    
    $PublicOutputFiles = @(
        ($PublicTempPath + "/ReadMe.txt"), 
        ($SourcePath + "/tSQLtSnippets(SQLPrompt).zip")
    );
    $ValidationOutputFiles = @(
        ($SourcePath + "/Version.txt"), 
        ($SourcePath + "/CommitId.txt"), 
        ($SourcePath + "/tSQLt.tests.zip"), 
        ($SourcePath + "/CreateBuildLog.sql"),
        ($SourcePath + "/GetFriendlySQLServerVersion.sql")
    ); 

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;

    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $__ = New-Item -ItemType "directory" -Path $PublicOutputPath;
    $__ = New-Item -ItemType "directory" -Path $tSQLtDacpacPath;
    $__ = New-Item -ItemType "directory" -Path $ValidationOutputPath;
    $__ = New-Item -ItemType "directory" -Path $SourcePath;
    $__ = New-Item -ItemType "directory" -Path $DacpacSourcePath;

    Log-Output("Copying source files...")
        $files = @(
            "$($tSQLtBuildPath)Version.txt",
            "$($tSQLtBuildPath)CommitId.txt",
            "$($tSQLtBuildPath)CreateBuildLog.sql",
            "$($tSQLtBuildPath)GetFriendlySQLServerVersion.sql",
            "$($tSQLtTestsPath)tSQLt.tests.zip",
            "$($tSQLtBuildPath)tSQLtSnippets(SQLPrompt).zip",
            "$($tSQLtBuildPath)tSQLtFiles.zip"
        );
        $files | ForEach-Object{$_ | Copy-Item -Destination $SourcePath}
        Get-ChildItem $DacpacBuildPath | Copy-Item -Destination $DacpacSourcePath

    <# Copy files to temp path #>
    Expand-Archive -Path (Join-Path $SourcePath "tSQLtFiles.zip" | Resolve-Path) -DestinationPath $PublicTempPath;
    # Get-ChildItem -Path ($dir + "/output/DacpacBuild/tSQLtFacade.*.dacpac") | Copy-Item -Destination $FacadeDacpacPath;
    Get-ChildItem -Path $DacpacSourcePath -Filter 'tSQLt.*.dacpac' | Copy-Item -Destination $tSQLtDacpacPath;

    Copy-Item (Join-Path $PublicTempPath "ReleaseNotes.txt" | Resolve-Path) -Destination (Join-Path $PublicTempPath "ReadMe.txt");

    # Write-Warning "BuildPackage Pre-Zip:"
    # Write-Warning "----------------------------------------------------------------"
    # Get-ChildItem $PublicTempPath -Recurse |FT;
    # Write-Warning "----------------------------------------------------------------"
    # Get-ChildItem $ValidationOutputFiles -Recurse |FT;
    # Write-Warning "----------------------------------------------------------------"

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
