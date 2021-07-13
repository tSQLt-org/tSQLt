$GetUTCTimeStamp = {param();(Get-Date).ToUniversalTime().ToString('[yyyy-MM-ddTHH:mm:ss.fffffff UTC]');};

Function Log-Output{[cmdletbinding()]Param([parameter(ValueFromPipeline)]$I);Process{Write-Host ([string]::Concat($GetUTCTimeStamp.Invoke()[0],[string]::Concat($I)));};};

Log-Output "This is a test.";
