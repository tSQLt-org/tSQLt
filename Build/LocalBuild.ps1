using module "./CommonFunctionsAndMethods.psm1";

param(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $ServerName = 'localhost,1433',
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][string] $UserName = "sa" ,
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][securestring] $Password = (ConvertTo-SecureString "P@ssw0rd" -AsPlainText),
    [Parameter(Mandatory=$true, ParameterSetName = 'TrustedCon')][ValidateNotNullOrEmpty()][switch] $TrustedConnection,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tSQLt.TmpBuild.DacPacBuild',
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $pfxFilePath = (Join-Path $env:TSQLTCERTPATH "tSQLtOfficialSigningKey.pfx" |Resolve-Path),
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][securestring] $pfxPassword = (ConvertTo-SecureString -String "$env:TSQLTCERTPASSWORD" -Force -AsPlainText),
    [Parameter(Mandatory=$false)][switch]$KeepTemp,
    [Parameter(Mandatory=$false, ParameterSetName="IgnoreMe")][string]$IgnoreMe
)
$PSDefaultParameterValues = $PSDefaultParameterValues.clone()
$PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}

Get-Module -Name CommonFunctionsAndMethods | Select-Object Name, Path, Version

function CleanTemp {
    param (
        [Parameter(Mandatory=$false)][bool]$KeepTemp = $false
    )
    if(! $KeepTemp){
        if (Test-Path -Path "temp") {
            Remove-Item -Path "temp" -Recurse -Force
        }    
    }
}

$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{

    if($TrustedConnection){
        Write-Warning('GH:TC')
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,"LocalBuild");
    }else{
        Write-Warning('GH:UP')
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,$UserName,$Password,"LocalBuild");
    }

    Log-Output('');
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output("|              ***** Executing Local tSQLt Build *****               |");
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output('');

    
    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Cleaning Environment              :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    if (Test-Path -Path "output") {
        Remove-Item -Path "output" -Recurse -Force
    }
    CleanTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting CLR Build                :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildCLR.ps1 -pfxFilePath $pfxFilePath -pfxPassword $pfxPassword
    CleanTemp $KeepTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt Build              :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_Build.ps1
    CleanTemp $KeepTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt Tests Build        :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildTests.ps1
    CleanTemp $KeepTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt DacPac Build       :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')
# Write-Warning($SqlServerConnection)
    & ./tSQLt_BuildDacpac.ps1 -SqlServerConnection $SqlServerConnection -DacPacDatabaseName $DatabaseName
    CleanTemp $KeepTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Packaging tSQLt & DACPACs         :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildPackage.ps1
    CleanTemp $KeepTemp;

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Build Finished                    :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    
}
catch{
    throw;
}
finally{
    Pop-Location
}