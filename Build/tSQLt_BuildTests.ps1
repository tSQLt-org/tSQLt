using module "./CommonFunctionsAndMethods.psm1";

$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    $OutputPath = (Join-Path $invocationDir "./output/tSQLtTests/");
    $TempPath = (Join-Path $invocationDir "./temp/tSQLtTests/");
    $PackagePath = (Join-Path $TempPath "Package/");

    <# Clean #>
    Remove-DirectoryQuietly -Path $TempPath;
    Remove-DirectoryQuietly -Path $OutputPath;
    <# Init directories, capturing the return values in a variable so that they don't print. #>
    $_ = New-Item -ItemType "directory" -Path $TempPath;
    $_ = New-Item -ItemType "directory" -Path $PackagePath;
    $_ = New-Item -ItemType "directory" -Path $OutputPath;

    Log-Output("Generating CREATE ASSEMBLY statement for tSQLtTestUtilCLR...")
        $tSQLtTestUtilCLRDLLPath = (Join-Path (Get-Location) "./temp/tSQLtBuild/tSQLtCLR/tSQLtTestUtilCLR.dll") | Resolve-Path
        $tSQLtTestUtilCLRSQLPath = (Join-Path (Get-Location) "../TestUtil/tSQLtTestUtilCLR.mdl.sql") | Resolve-Path
        $tSQLtTestUtilCLROutputPath = (Join-Path $TempPath "CreateTestUtilAssembly.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $tSQLtTestUtilCLROutputPath $tSQLtTestUtilCLRDLLPath $tSQLtTestUtilCLRSQLPath 0x000000 "0xZZZZZ" 20000 "+`n0x"

    Log-Output("Generating CREATE ASSEMBLY statement for UnsignedEmpty...")
        $UnsignedEmptyCLRDLLPath = (Join-Path (Get-Location) "./temp/tSQLtBuild/tSQLtCLR/UnsignedEmpty.dll") | Resolve-Path
        $UnsignedEmptyCLRSQLPath = (Join-Path (Get-Location) "../TestUtil/GetUnsignedEmptyBytes.mdl.sql") | Resolve-Path
        $UnsignedEmptyCLROutputPath = (Join-Path $TempPath "GetUnsignedEmptyBytes.sql") 
        ./tSQLt_Build/CreateAssemblyGenerator.ps1 $UnsignedEmptyCLROutputPath $UnsignedEmptyCLRDLLPath $UnsignedEmptyCLRSQLPath 0x000000 "0xZZZZZ" 20000 "+`n0x"

    Log-Output("Building TestUtil.sql file...")
        $tSQLtSeparatorPath = (Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path
        $tSQLtFileListPath = (Join-Path (Get-Location) "../TestUtil/BuildOrder.txt") | Resolve-Path
        $tSQLtClassOutputPath = (Join-Path $PackagePath "TestUtil.sql") 
        $replacements = @(
            @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
            @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
        );
        ./tSQLt_Build/ConcatenateFiles.ps1 -OutputFile $tSQLtClassOutputPath -SeparatorTemplate $tSQLtSeparatorPath -InputPath $tSQLtFileListPath -Replacements $replacements

    Log-Output("Building TestUtilTests.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "TestUtilTests.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../TestUtilTests") | Resolve-Path) 
            IncludePattern= "tSQLt_testutil*test.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building TestUtilTests.SA.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "TestUtilTests.SA.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../TestUtilTests") | Resolve-Path) 
            IncludePattern= "tSQLt_testutil*test_SA.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building AllTests.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "AllTests.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Tests") | Resolve-Path) 
            IncludePattern= "*.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building AllTests.EXTERNAL_ACCESS.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "AllTests.EXTERNAL_ACCESS.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Tests.EXTERNAL_ACCESS") | Resolve-Path) 
            IncludePattern= "*.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building AllTests.EXTERNAL_ACCESS_KEY_EXISTS.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "AllTests.EXTERNAL_ACCESS_KEY_EXISTS.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Tests.EXTERNAL_ACCESS_KEY_EXISTS") | Resolve-Path) 
            IncludePattern= "*.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building AllTests.SA.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "AllTests.SA.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Tests.SA") | Resolve-Path) 
            IncludePattern= "*.class.sql"  
            Replacements= @(
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Copying misc files...")
        $files = @(
            "../../Tests/BootStrapTest.sql",
            "ExecuteAs(tSQLt.Build).sql",
            "ExecuteAs(tSQLt.Build.SA).sql",
            "ExecuteAsCleanup.sql"
            "Drop(tSQLtAssemblyKey)(Pre2017).sql",
            "Install(tSQLtAssemblyKey).sql",
            "ChangeDbAndExecuteStatement(tSQLt.Build).sql",
            "EnableExternalAccess.sql",
            "Drop(master.tSQLt_testutil).sql",
            "Install(master.tSQLt_testutil).sql",
            "GetFailedTestCount.sql",
            "Add(tSQLt.Built)ToExampleDB.sql",
            "UseTempDb.sql",
            "../../Examples/TestThatExamplesAreDeployed.sql"
        );
        $files|%{(Join-Path $invocationDir 'SQL' $_ | Resolve-Path) | Copy-Item -Destination $PackagePath}

    Log-Output("Building CreateBuildDb.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "CreateBuildDb.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "./SQL/CreateBuildDbBuildOrder.txt") | Resolve-Path) 
            Replacements= @(
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters

    Log-Output("Building ResetValidationServer.sql file...")
        $parameters = @{
            OutputFile= (Join-Path $TempPath "ResetValidationServer.tmp.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Source/ResetValidationServerBuildOrder1.txt") | Resolve-Path) 
            Replacements= @(
                @{'s'='tSQLt.';'r'='#';}
                @{'s'="OBJECT_ID('#";'r'="OBJECT_ID('tempdb..#";}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters
        $parameters = @{
            OutputFile= (Join-Path $PackagePath "ResetValidationServer.sql")
            SeparatorTemplate= ((Join-Path (Get-Location) "./SQL/SeparatorTemplate.sql") | Resolve-Path)
            InputPath= ((Join-Path (Get-Location) "../Source/ResetValidationServerBuildOrder2.txt") | Resolve-Path) 
            Replacements= @(
                @{'s'='---Build-';'r'='';}
                @{'s'='---Build+';'r'='';}
                @{'s'="(?m)^\s*--.*";'r'='';isRegex=$true;}
                @{'s'='(?m)^(?:[\t ]*(?:\r?\n|\r))+';'r'='';isRegex=$true;}
                @{'s'='(?m)^\s*GO\s*((\r?\n)\s*GO\s*)+$';'r'='GO';isRegex=$true;}
            )
        }
        ./tSQLt_Build/ConcatenateFiles.ps1 @parameters
     
    Log-Output("Packaging Test Files...")
        $compress = @{
            CompressionLevel = "Optimal"
            DestinationPath = (Join-Path $outputPath "tSQLt.tests.zip")
            }
        Get-ChildItem -Path (Join-Path $PackagePath "*") | Compress-Archive @compress
    
}
finally{
    Pop-Location
}