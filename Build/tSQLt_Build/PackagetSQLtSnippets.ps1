$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $PSScriptRoot '../CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $snippetsPath = Join-Path $invocationDir '../../Snippets' | Resolve-Path;
    $outputPath = Join-Path $invocationDir '../output/tSQLtBuild' |Resolve-Path;
    $tempPath = Join-Path $invocationDir '../temp/tSQLtBuild/SQLPromptSnippets';
    Remove-DirectoryQuietly -Path $tempPath;
    $_ = New-Item -ItemType "directory" -Path $tempPath;


    $fileList = Get-ChildItem -path (Join-Path $snippetsPath '*') -include "*.sqlpromptsnippet","ReadMe.txt"
    $fileList | Copy-Item -Destination $tempPath

    $compress = @{
        CompressionLevel = "Optimal"
        DestinationPath = (Join-Path $outputPath "tSQLtSnippets(SQLPrompt).zip")
        }
    Get-ChildItem -Path (Join-Path $tempPath "*") | Compress-Archive @compress
}
finally{
    Pop-Location
}