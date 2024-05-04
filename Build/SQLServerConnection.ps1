if (-not ([System.Management.Automation.PSTypeName]'SqlServerConnection').Type) {

    class SqlServerConnection {
      hidden [string]$ServerName
      hidden [string]$UserName
      hidden [System.Security.SecureString]$Password
      hidden [bool]$TrustedConnection
      hidden [string]$ApplicationName
      hidden [string]$BaseConnectionString = "Connect Timeout=60;Encrypt=false;TrustServerCertificate=true;"
  
      SqlServerConnection([string]$ServerName, [string]$UserName, [System.Security.SecureString]$Password,[string]$ApplicationName) {
        $this.ServerName = $ServerName.Trim()
        $this.UserName = $UserName.Trim()
        $this.Password = $Password
        $this.TrustedConnection = false
        $this.ApplicationName = $ApplicationName.Trim()
      }
      # SqlServerConnection([string]$ServerName,[string]$ApplicationName) {
      #   $this.ServerName = $ServerName.Trim()
      #   $this.UserName = $null
      #   $this.Password = $null
      #   $this.TrustedConnection = true
      #   $this.ApplicationName = $ApplicationName.Trim()
      # }
  
      [string] ToString() {
        
  
        return @{
          ServerName= $($this.ServerName)
          UserName= $($this.UserName)
          Password= (ConvertFrom-SecureString $this.Password -AsPlainText)
          TrustedConnection= $($this.TrustedConnection)
          ApplicationName= $($this.ApplicationName)
          BaseConnectionString= $($this.BaseConnectionString)
        }| ConvertTo-Json -Compress
      } 
  
      static [string] ToStringStatic([SqlServerConnection]$instance) {
          if ($null -eq $instance) {
              return "$null"
          }
          else {
              return $instance.ToString()
          }
      }
  
      [string] GetServerName() {
          return $this.ServerName
      }
  
      [string] GetUserName() {
          return $this.UserName
      }
  
      [System.Security.SecureString] GetPassword() {
          return $this.Password
      }
  
      [bool] GetTrustedConnection() {
          return $this.TrustedConnection
      }
  
      hidden [string] EscapeAndQuoteConnectionStringValue([string]$value) {
        return "`"$( $value.Replace('"', '""') )`""
      }
  
      [string] GetConnectionString([string]$DatabaseName = '', [string]$ApplicationNameSuffix = '') {
          $connectionString = "Server=$($this.EscapeAndQuoteConnectionStringValue($this.ServerName));"
  
          if ($this.TrustedConnection) {
              $connectionString += "Integrated Security=SSPI;"
          } else {
            $connectionString += "User Id=$($this.EscapeAndQuoteConnectionStringValue($this.UserName));"
            $connectionString += "Password=$($this.EscapeAndQuoteConnectionStringValue((ConvertFrom-SecureString $this.Password -AsPlainText)));"
          }
          if(![string]::IsNullOrWhiteSpace($DatabaseName)){
            $connectionString += "Initial Catalog=$($this.EscapeAndQuoteConnectionStringValue($DatabaseName));"
          }
          $PApplicationName = $this.ApplicationName;
          if(![string]::IsNullOrWhiteSpace($ApplicationNameSuffix)){
            $PApplicationName+=".$ApplicationNameSuffix"
          }
          $connectionString += "Application Name=$($this.EscapeAndQuoteConnectionStringValue($PApplicationName));"
          return $this.BaseConnectionString+$connectionString
      }
    }
  }
  