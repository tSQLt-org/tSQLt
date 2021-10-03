
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Username,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $anotherString
);

$SqlCmdVariables = "DatabaseName=master", "ColumnName=name";
$Results = (Invoke-Sqlcmd -ServerInstance $ServerName -Username $Username -Password $anotherString -Query "SET STATISTICS XML ON; SELECT `$(ColumnName) FROM sys.databases WHERE [name] = '`$(DataBaseName)';" -Variable $SqlCmdVariables -MaxCharLength 10MB);
$Plan = [xml]$Results[$Results.GetUpperBound(0)].Item(0);
# $Plan.Save("C:\temp\test.sqlplan");
$Plan;

