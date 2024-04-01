using module "./CommonFunctionsAndMethods.psm1";
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $pfxFilePath ,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][securestring] $pfxPassword
)
Push-Location -Path $PSScriptRoot
Write-Warning((Get-Location).Path)
try{
    $OutputPath = "./output/tSQLtCLR/";
    $TempPath = "./temp/tSQLtCLR/";

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;
    Get-ChildItem -Path ("../tSQLtCLR/") -Recurse -Include bin, obj|Foreach-Object{Remove-DirectoryQuietly -Path $_}

    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $__=$__;
    $__ = New-Item -ItemType "directory" -Path $TempPath;
    $__ = New-Item -ItemType "directory" -Path $OutputPath;

    ../tSQLtCLR/Build.ps1 -pfxFilePath $pfxFilePath -pfxPassword $pfxPassword

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