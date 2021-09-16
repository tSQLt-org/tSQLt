Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$repoURL,
    $debugOnString="false"
);

$debugOn = ($debugOnString -eq "true");
if ($debugOn) {
    $DebugPreference = "Continue";
}

Write-Output "Got here.";
