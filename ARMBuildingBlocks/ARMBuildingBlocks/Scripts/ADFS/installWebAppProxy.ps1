Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName



)

# example of command
# .\installWebAppProxy.ps1 -AdminUser administrator1 -AdminPassword "Pag`$1Lab00000" -NetBiosDomainName patterns2 -FederationName pnpadfs.patternspractices.net 

Install-WindowsFeature -IncludeManagementTools -name Web-Application-Proxy
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

#uncomment those lines to install the cert or install them manually
#certutil.exe -privatekey -p Pag`$1Lab -importPFX my C:\certificates\pnpadfsfinal.pfx NoExport
#certutil.exe -privatekey -importPFX root C:\certificates\pnpadfsroot.cer NoExport


$thumbprint=(Get-ChildItem -DnsName $federationName -Path cert:\LocalMachine\My).Thumbprint

Install-WebApplicationProxy -FederationServiceTrustCredential $Credential -CertificateThumbprint $thumbprint -FederationServiceName $federationName 

Add-WebApplicationProxyApplication -BackendServerUrl "https://$federationName" -ExternalCertificateThumbprint $thumbprint -ExternalUrl "https://$federationName" -Name "Partner ADFS" -ExternalPreAuthentication PassThrough




