Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $CommitId
);

$toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtBuild/tSQLtFiles.zip"
    }
Get-ChildItem -Path "temp/tSQLtBuild/*" -Include $toBeZipped | Compress-Archive @compress

Copy-Item "temp/tSQLtBuild/ReleaseNotes.txt" -Destination "output/tSQLtBuild/ReadMe.txt";
Copy-Item "temp/tSQLtBuild/Version.txt" -Destination "output/tSQLtBuild/";
Copy-Item "temp/tSQLtBuild/tSQLt.class.sql" -Destination "output/tSQLtBuild/";

<#--=======================================================================-->
<!--========                 Write CommitId.txt                   =========-->
<!--=======================================================================-#>

Set-Content -Path "output/tSQLtBuild/CommitId.txt" -Value $CommitId;
