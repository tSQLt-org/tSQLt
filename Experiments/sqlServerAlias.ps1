# List existing aliases
Get-WmiObject -Namespace 'root\Microsoft\SqlServer\ComputerManagement15' -Class 'SqlServerAlias' |
    Format-Table -Property 'AliasName', 'ServerName', 'ProtocolName', 'ConnectionString'

# Delete existing aliases
$alias = Get-WmiObject -namespace 'root\Microsoft\SqlServer\ComputerManagement15' -class 'SqlServerAlias' -filter "AliasName='Dev_tSQLt'"
$alias.Delete()

# Example script to create an alias
$alias = ([wmiclass] '\\.\root\Microsoft\SqlServer\ComputerManagement15:SqlServerAlias').CreateInstance()
$alias.AliasName = 'Dev_tSQLt'
$alias.ConnectionString = '41433' #connection specific parameters depending on the protocol
$alias.ProtocolName = 'tcp'
$alias.ServerName = '810D79BF7E9C'
$alias.Put() | Out-Null;