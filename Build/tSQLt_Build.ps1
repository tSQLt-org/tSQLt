$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $invocationDir 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    $buildPath = $invocationDir;
    $sourcePath = (Join-Path $invocationDir '../Source' | Resolve-Path);

    $OutputPath = "./output/tSQLtBuild/";
    $TempPath = "./temp/tSQLtBuild/";

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;
    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $__ = New-Item -ItemType "directory" -Path $TempPath;
    $__ = New-Item -ItemType "directory" -Path $OutputPath;

    Log-Output("Createting DROP CLASS statement..")
        ./tSQLt_Build/CreateDropClassStatement.ps1

    Log-Output("Copying files...")
        $fileList = ("License.txt","ReleaseNotes.txt")
        $fileList|ForEach-Object{(Join-Path $buildPath $_ | Resolve-Path)|Copy-Item -Destination $TempPath}

    Log-Output("Unzipping tSQLtCLR DLLs...")
        Expand-Archive ./output/tSQLtCLR/tSQLtCLR.zip -DestinationPath ./temp/tSQLtBuild/tSQLtCLR

    Log-Output("Generating CREATE ASSEMBLY statement...")
        $tSQLtCLRDLLPath = (Join-Path $TempPath "tSQLtCLR/tSQLtCLR.dll") | Resolve-Path
        $tSQLtCLRSQLPath = (Join-Path $sourcePath "tSQLtCLR.mdl.sql") | Resolve-Path
        $tSQLtCLROutputPath = (Join-Path $TempPath "CreateAssembly.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $tSQLtCLROutputPath $tSQLtCLRDLLPath $tSQLtCLRSQLPath 0x000000 "0xZZZZZ" 200 "'+`n'"

    Log-Output("Generating Version.txt...")
        $getAssemblyInfoPath = (Join-Path $buildPath "tSQLt_Build/GetAssemblyInfo.ps1" | Resolve-Path)
        $tSQLtVersion = & $getAssemblyInfoPath $tSQLtCLRDLLPath -v
        Set-Content -Path (Join-Path $tempPath "Version.txt") -Value $tSQLtVersion;
        Log-Output("+------------------------------------------------------+");
        $VersionOutput = "tSQLt Version: V$tSQLtVersion".PadRight(50,' ');
        Log-Output("|  $VersionOutput  |");
        Log-Output("+------------------------------------------------------+");

    Log-Output("Generating GetAssemblyKeyBytes function...")
        $tSQLtCLRDLLPath = (Join-Path $TempPath "tSQLtCLR/tSQLtAssemblyKey.dll") | Resolve-Path
        $tSQLtCLRSQLPath = (Join-Path $sourcePath "tSQLt.Private_GetAssemblyKeyBytes.mdl.sql") | Resolve-Path
        $tSQLtCLROutputPath = (Join-Path $TempPath "tSQLt.Private_GetAssemblyKeyBytes.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $tSQLtCLROutputPath $tSQLtCLRDLLPath $tSQLtCLRSQLPath 0x000000 0x000001 200 "+`n0x"

    Log-Output("Generating tSQLt.class.sql file...")
        $tSQLtSeparatorPath = (Join-Path $buildPath "SQL/SeparatorTemplate.sql") | Resolve-Path
        $tSQLtFileListPath = (Join-Path $sourcePath "BuildOrder.txt") | Resolve-Path
        $tSQLtClassOutputPath = (Join-Path $TempPath "tSQLt.class.sql") 
        $replacements = @(
            @{"s"='$LATEST-BUILD-NUMBER$';"r"=$tSQLtVersion}
            @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
            @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
        );
        ./tSQLt_Build/ConcatenateFiles.ps1 -OutputFile $tSQLtClassOutputPath -SeparatorTemplate $tSQLtSeparatorPath -InputPath $tSQLtFileListPath -Bracket "---Build" -Replacements $replacements

    Log-Output("Updating ReleaseNotes...")
        $releaseNotesPath = (Join-Path $buildPath "ReleaseNotes.txt") | Resolve-Path
        (Get-Content -Path $releaseNotesPath).Replace('LATEST-BUILD-NUMBER', $tSQLtVersion) | Set-Content -Path $releaseNotesPath

    Log-Output("Creating PrepareServer.sql...")
        $PrepareServerSeparatorPath = (Join-Path $buildPath "SQL/SeparatorTemplate.sql") | Resolve-Path
        $PrepareServerFileListPath = (Join-Path $sourcePath "PrepareServerBuildOrder.txt") | Resolve-Path
        $PrepareServerOutputPath = (Join-Path $TempPath "PrepareServer.sql") 
        $PrepareServerReplacements = @(
            @{'s'='tSQLt.';'r'='#';},
            @{'s'="OBJECT_ID('#";'r'="OBJECT_ID('tempdb..#";},
            @{'s'='---Build-';'r'='';},
            @{'s'='---Build+';'r'='';},
            @{'s'="(?m)^\s*--.*";'r'='';isRegex=$true;}
            @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;},
            @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
        );
        ./tSQLt_Build/ConcatenateFiles.ps1 -OutputFile $PrepareServerOutputPath -SeparatorTemplate $PrepareServerSeparatorPath -InputPath $PrepareServerFileListPath -Replacements $PrepareServerReplacements

    Log-Output("Creating Example.sql...")
        $ExampleSeparatorPath = (Join-Path $buildPath "SQL/SeparatorTemplate.sql") | Resolve-Path
        $ExampleFileListPath = (Join-Path $buildPath "../Examples/BuildOrder.txt") | Resolve-Path
        $ExampleOutputPath = (Join-Path $TempPath "Example.sql") 
        $ExampleReplacements = @(
            @{'s'="(?m)^\s*---*$";'r'='';isRegex=$true;}
            @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;},
            @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
        );
        ./tSQLt_Build/ConcatenateFiles.ps1 -OutputFile $ExampleOutputPath -SeparatorTemplate $ExampleSeparatorPath -InputPath $ExampleFileListPath -Replacements $ExampleReplacements

    Log-Output("Creating CommitId.txt...")
        $CommitIdPath = (Join-Path $tempPath "CommitId.txt");
        (& git rev-parse HEAD)|Set-Content -Path $CommitIdPath;
        Log-Output("+--------------------------------------------------------------------------+");
        $ComitIdOutput = ("Git Commit Id: "+(Get-Content -Path $CommitIdPath )).PadRight(70,' ');
        Log-Output("|  $ComitIdOutput  |");
        Log-Output("+--------------------------------------------------------------------------+");



    Log-Output("Creating GetFriendlySQLServerVersion.sql...")
        $templateContent = Get-Content -path (Join-Path $buildPath "SQL/GetFriendlySQLServerVersion.template.sql");
        $sqlFile1Content = Get-Content -path (Join-Path $sourcePath "tSQLt.FriendlySQLServerVersion.sfn.sql");
        $sqlFile2Content = Get-Content -path (Join-Path $sourcePath "tSQLt.Private_SplitSqlVersion.sfn.sql");
    
        $snip1Content = (Get-SnipContent $sqlFile1Content  "/*StartSnip*/" "/*EndSnip*/");
        $snip2Content = (Get-SnipContent $sqlFile2Content "/*StartSnip*/" "/*EndSnip*/");
    
        $FinalContent = (($templateContent.Replace("/*snip1content*/",$snip1Content).Replace("/*snip2content*/",$snip2Content)) -join [System.Environment]::NewLine);
        Set-Content -Path (Join-Path $tempPath 'GetFriendlySQLServerVersion.sql') -Value $FinalContent;
    
    Log-Output("Creating CreateBuildLog.sql...")
        $testUtilContent = Get-Content -path (Join-Path $buildPath "../TestUtil/tSQLt_testutil.class.sql" | Resolve-Path);
        $CreateBuildLogRaw = (Get-SnipContent $testUtilContent "/*CreateBuildLogStart*/" "/*CreateBuildLogEnd*/");
        $CreateBuildLog = ($CreateBuildLogRaw -join [System.Environment]::NewLine).Replace("tSQLt_testutil.CreateBuildLog","#CreateBuildLog");
        $CreateBuildLog = ($CreateBuildLog + [System.Environment]::NewLine + "EXEC #CreateBuildLog @TableName='"+'$(BuildLogTableName)'+"';" + [System.Environment]::NewLine);
        Set-Content -Path (Join-Path $tempPath 'CreateBuildLog.sql') -Value ($CreateBuildLog);
        
    Log-Output("Packaging tSQLt...")
        $toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
        $compress = @{
            CompressionLevel = "Optimal"
            DestinationPath = (Join-Path $outputPath "tSQLtFiles.zip")
            }
        Get-ChildItem -Path (Join-Path $tempPath "*") -Include $toBeZipped | Compress-Archive @compress
    
        $toBeCopied = @("Version.txt", "tSQLt.class.sql", "CommitId.txt", "GetFriendlySQLServerVersion.sql", "CreateBuildLog.sql");
        $toBeCopied | ForEach-Object{(Join-Path $TempPath $_ | Resolve-Path )| Copy-Item -Destination $outputPath;}
        Copy-Item (Join-Path $tempPath "ReleaseNotes.txt" | Resolve-Path) -Destination (Join-Path $outputPath "ReadMe.txt");
    
    Log-Output("Creating tSQLt Snippets...")
        & ./tSQLt_Build/PackagetSQLtSnippets.ps1

}
catch{
    throw
}
finally{
    Pop-Location
}