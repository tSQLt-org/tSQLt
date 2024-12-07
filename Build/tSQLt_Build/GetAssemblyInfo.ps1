param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]$dllPath,
    [Parameter(Mandatory=$true, ParameterSetName="Version")]
    [switch]$v,
    [Parameter(Mandatory=$true, ParameterSetName="Key")]
    [switch]$k,
    [Parameter(Mandatory=$true, ParameterSetName="Token")]
    [switch]$t
)

function Get-AssemblyInfo {
    param(
        [string]$dllPath,
        [switch]$v,
        [switch]$k,
        [switch]$t
    )

    try {
        $assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($dllPath)

        if($v) {
            return $assemblyName.Version.ToString()
        }
        elseif($k){
            $publicKey = $assemblyName.GetPublicKey()
            if ($null -eq $publicKey -or $publicKey.Length -eq 0) {
                return ""
            } else {
                return [BitConverter]::ToString($publicKey) -replace '-'
            }
        }
        elseif($t){
            $publicKeyToken = $assemblyName.GetPublicKeyToken()
            if ($null -eq $publicKeyToken -or $publicKeyToken.Length -eq 0) {
                return ""
            } else {
                return [BitConverter]::ToString($publicKeyToken) -replace '-'
            }
        }
    } catch {
        Write-Error "Error processing assembly: $_"
        exit 1
    }
}

(Get-AssemblyInfo -dllPath $dllPath -v:$v -k:$k -t:$t)

