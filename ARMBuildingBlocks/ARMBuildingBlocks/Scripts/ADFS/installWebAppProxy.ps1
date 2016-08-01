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
###############################################
# Manual step for install certificate to the ADFS WAeb Applicaiton Proxy VMs:

# 1. Make sure you have a certificate (e.g. adfs.contoso.com.pfx) either self created or signed by VerifSign, Go Daddy, DigiCert, and etc.

# 2. RDP to the each ADFS VM (adfs1-vm, adfs2-vm, ...)

# 3. Copy to c:\temp the following file
#		c:\temp\certutil.exe
#		c:\temp\adfs.contoso.com.pfx 
#       c:\MyFakeRootCertificateAuthority.cer  (if you created the above cert yourself \

# 4. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\adfs.contoso.com.pfx NoExport
#    Run the following command prompt as admin \(if you created the above cert yourself \)
#	    certutil.exe -addstore Root C:\temp\MyFakeRootCertificateAuthority.cer 

# 5. Start MMC, Add Certificates Snap-in, sellect Computer account, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com
#    If you created the above cert yourself, verify the the following certificate is installed:
#      \Certificates (Local Computer)\Trusted Root Certification Authorities\Certificates\MyFakeRootCertificateAuthority 


###############################################

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

