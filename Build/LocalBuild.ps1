param(
    [Parameter(Mandatory=$true, ParameterSetName="DBC")][ValidateNotNullOrEmpty()][string] $ServerName = 'localhost,1433',
    [Parameter(Mandatory=$true, ParameterSetName="DBC")][ValidateNotNullOrEmpty()][string] $Login = '-U "sa" -P "P@ssw0rd"',
    [Parameter(Mandatory=$true, ParameterSetName="DBC")][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tSQLtDacPacBuild',
    [Parameter(Mandatory=$false, ParameterSetName="IgnoreMe")][string]$IgnoreMe
)
$PSDefaultParameterValues = $PSDefaultParameterValues.clone()
$PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}

$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
try{
    .(Join-Path $PSScriptRoot 'CommonFunctionsAndMethods.ps1'| Resolve-Path);

    Log-Output('');
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output("|              ***** Executing Local tSQLt Build *****               |");
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output('');

    
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

    & ./tSQLt_BuildDacpac.ps1 -ServerName $ServerName -DatabaseName $DatabaseName -Login $Login

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