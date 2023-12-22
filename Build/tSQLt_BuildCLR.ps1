using module "./CommonFunctionsAndMethods.psm1";
Push-Location -Path $PSScriptRoot

try{
    $OutputPath = "./output/tSQLtCLR/";
    $TempPath = "./temp/tSQLtCLR/";

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;
    Get-ChildItem -Path ("../tSQLtCLR/") -Recurse -Include bin, obj|Foreach-Object{Remove-DirectoryQuietly -Path $_}

    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $_ = New-Item -ItemType "directory" -Path $TempPath;
    $_ = New-Item -ItemType "directory" -Path $OutputPath;

    ../tSQLtCLR/Build.ps1

    Get-ChildItem -Path ("../tSQLtCLR/*/bin") -Recurse -Include *.dll | Copy-Item -Destination $TempPath;

    $compress = @{
        CompressionLevel = "Optimal"
        DestinationPath = $OutputPath + "/tSQLtCLR.zip"
    }
    Get-ChildItem -Path $TempPath | Compress-Archive @compress
}
finally{
    Pop-Location
}