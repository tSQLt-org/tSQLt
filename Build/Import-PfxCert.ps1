param($PfxFilePath, $Password)
 
$absolutePfxFilePath = Resolve-Path -Path $PfxFilePath
Write-Output "Importing store certificate &#39;$absolutePfxFilePath&#39;..."
 
Add-Type -AssemblyName System.Security
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($absolutePfxFilePath, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
$store = new-object system.security.cryptography.X509Certificates.X509Store -argumentlist "MY", CurrentUser
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::"ReadWrite")
$store.Add($cert)
$store.Close()

#Source: http://blog.danskingdom.com/creating-a-pfx-certificate-and-applying-it-on-the-build-server-at-build-time/
