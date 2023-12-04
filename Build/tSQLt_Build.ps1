Push-Location -Path $PSScriptRoot
.("./CommonFunctionsAndMethods.ps1");

try{
    $OutputPath = "./output/tSQLtBuild/";
    $TempPath = "./temp/tSQLtBuild/";

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;
    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $_ = New-Item -ItemType "directory" -Path $TempPath;
    $_ = New-Item -ItemType "directory" -Path $OutputPath;

    Log-Output("Createting DROP CLASS statement..")
        ./tSQLt_Build/CreateDropClassStatement.ps1

    Log-Output("Unzipping tSQLtCLR DLLs...")
        Expand-Archive ./output/tSQLtCLR/tSQLtCLR.zip -DestinationPath ./temp/tSQLtBuild/tSQLtCLR

    Log-Output("Generating CREATE ASSEMBLY statement...")
        $tSQLtCLRDLLPath = (Join-Path (Get-Location) "./temp/tSQLtBuild/tSQLtCLR/tSQLtCLR.dll") | Resolve-Path
        $tSQLtCLRSQLPath = (Join-Path (Get-Location) "../Source/tSQLtCLR.mdl.sql") | Resolve-Path
        $tSQLtCLROutputPath = (Join-Path $TempPath "CreateAssembly.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $tSQLtCLROutputPath $tSQLtCLRDLLPath $tSQLtCLRSQLPath 0x000000 "0xZZZZZ" 200 "'+`n'"

    Log-Output("Generating GetAssemblyKeyBytes function...")
        $tSQLtCLRDLLPath = (Join-Path (Get-Location) "./temp/tSQLtBuild/tSQLtCLR/tSQLtAssemblyKey.dll") | Resolve-Path
        $tSQLtCLRSQLPath = (Join-Path (Get-Location) "../Source/tSQLt.Private_GetAssemblyKeyBytes.mdl.sql") | Resolve-Path
        $tSQLtCLROutputPath = (Join-Path $TempPath "tSQLt.Private_GetAssemblyKeyBytes.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $tSQLtCLROutputPath $tSQLtCLRDLLPath $tSQLtCLRSQLPath 0x000000 0x000001 200 "+`n0x"


    Log-Output("Generating tSQLt.class.sql file...")
        $tSQLtSeparatorPath = (Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path
        $tSQLtFileListPath = (Join-Path (Get-Location) "../Source/BuildOrder.txt") | Resolve-Path
        $tSQLtClassOutputPath = (Join-Path $TempPath "tSQLt.class.sql") 
        ./tSQLt_Build/ConcatenateFiles.ps1 -OutputFile $tSQLtClassOutputPath -SeparatorTemplate $tSQLtSeparatorPath -InputPath $tSQLtFileListPath -Bracket "---Build"

}
finally{
    Pop-Location
}