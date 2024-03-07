using module "./CommonFunctionsAndMethods.psm1";

param(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $ServerName = 'localhost,1433',
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][string] $UserName = "sa" ,
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][securestring] $Password = (ConvertTo-SecureString "P@ssw0rd" -AsPlainText),
    [Parameter(Mandatory=$true, ParameterSetName = 'TrustedCon')][ValidateNotNullOrEmpty()][switch] $TrustedConnection,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tSQLtDacPacBuild',
    [Parameter(Mandatory=$false, ParameterSetName="IgnoreMe")][string]$IgnoreMe
)
$PSDefaultParameterValues = $PSDefaultParameterValues.clone()
$PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}

Get-Module -Name CommonFunctionsAndMethods | Select-Object Name, Path, Version


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
    if (Test-Path -Path "temp") {
        Remove-Item -Path "temp" -Recurse -Force
    }

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting CLR Build                :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildCLR.ps1

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt Build              :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_Build.ps1

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt Tests Build        :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildTests.ps1

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt DacPac Build       :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')
Write-Warning($SqlServerConnection)
    & ./tSQLt_BuildDacpac.ps1 -SqlServerConnection $SqlServerConnection

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Packaging tSQLt & DACPACs         :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildPackage.ps1

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