Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$mssqlVersion,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$acrURL, # eg. crn1234567890.azurecr.io
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$azSpCrBase64,
    $debugOnString="false"
);

$debugOn = ($debugOnString -eq "true");
if ($debugOn) {
    $DebugPreference = "Continue";
}

$decodedCreds = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("$azSpCrBase64"));
$creds = (ConvertFrom-Json -InputObject $decodedCreds) ;

Set-Location -Path ~\sourceRepo\docker;

docker login $acrURL --username $creds.clientId --password $creds.clientSecret

docker build . --file Dockerfile.$mssqlVersion --isolation=process -t $acrURL/mssql:$mssqlVersion

docker push $acrURL/mssql:$mssqlVersion
