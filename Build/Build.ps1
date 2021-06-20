

$toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLtBuild/tSQLt.zip"
    }
Get-ChildItem -Path "temp/tSQLtBuild/*" -Include $toBeZipped | Compress-Archive @compress

Copy-Item "temp/tSQLtBuild/ReleaseNotes.txt" -Destination "output/tSQLtBuild/ReadMe.txt";
Copy-Item "temp/tSQLtBuild/Version.txt" -Destination "output/tSQLtBuild/";
Copy-Item "temp/tSQLtBuild/tSQLt.class.sql" -Destination "output/tSQLtBuild/";

