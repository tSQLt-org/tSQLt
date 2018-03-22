param($PfxFilePath, $Password)
 
$absolutePfxFilePath = Resolve-Path -Path $PfxFilePath
Write-Output &quot;Importing store certificate &#39;$absolutePfxFilePath&#39;...&quot;
 
Add-Type -AssemblyName System.Security
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($absolutePfxFilePath, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
$store = new-object system.security.cryptography.X509Certificates.X509Store -argumentlist &quot;MY&quot;, CurrentUser
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::&quot;ReadWrite&quot;)
$store.Add($cert)
$store.Close()

#Source: http://blog.danskingdom.com/creating-a-pfx-certificate-and-applying-it-on-the-build-server-at-build-time/
