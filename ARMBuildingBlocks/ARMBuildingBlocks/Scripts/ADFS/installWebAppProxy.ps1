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
# Manual steps if you want to create and use a self singed test certificate contosotestcertificate

# 1. Log on your developer machine
# in order to Create self signed certificate in you developer PC

# 2. Download certutil.exe
# copy certutil.exe to c:/temp/

# 3. Create my fake root certificate authority
# makecert -sky exchange -pe -a sha256 -n "CN=MyFakeRootCertificateAuthority" -r -sv MyFakeRootCertificateAuthority.pvk MyFakeRootCertificateAuthority.cer -len 2048
# 
# verify that the foloiwng files are created
#	 C:/temp/MyFakeRootCertificateAuthority.cer
#	 C:/temp/MyFakeRootCertificateAuthority.pvk

# 4. Run command prompt as admin to use my fake root certificate authority to generate
#    a certificate for adfs.contoso.com
#
# makecert -sk pkey -iv MyFakeRootCertificateAuthority.pvk -a sha256 -n "CN=adfs.contoso.com , CN=enterpriseregistration.contoso.com" -ic MyFakeRootCertificateAuthority.cer -sr localmachine -ss my -sky exchange -pe

# 5. start mmc certificates console 
#	Expand to /Certificates (Local Computer)/Personal/Certificate/adfs.contoso.com 
#
#	Export the certificate with the private key to 
#    C:/temp/adfscontosocom.pfx

# 6. Make sure you have the following files in the C:\temp
#	 MyFakeRootCertificateAuthority.cer
#	 MyFakeRootCertificateAuthority.pvk
#    adfscontosocom.pfx

###################

# 7. RDP to the each ADFS VM.

# 8. copy 
#		certutil.exe
#		MyFakeRootCertificateAuthority.cer
#       adfscontosocom.pfx
#    to 
#		C:\temp\ 

# 9. Run the following command prompt as admin:
#	    certutil.exe -addstore "Root" "C:\temp\MyFakeRootCertificateAuthority.cer"
#   Open mmc Certificate Console and verify that it now has the following item
#      \Certificates (Local Computer)\Trusted Root Certification Authorities\Certificates\MyFakeRootCertificateAuthority 

# 10. Run the following command prompt as admin:
#  		certutil.exe -privatekey -importPFX my C:\temp\adfscontosocom.pfx NoExport

# 11. Start MMC, Add Certificates Console, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com issued by MyFakeRootCertificationAuthority 

###############################################
# If you have a public signed certificate adfs.contoso.com.pfx by VerifSign, Go Daddy, DigiCert, and etc.
# then Use the following Manual steps 

# 1. RDP to the each ADFS VM (adfs1-vm, adfs2-vm, ...)

# 2. copy to c:\temp the following file
#		c:\temp\certutil.exe
#		c:\temp\adfs.contoso.com.pfx 

# 3. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\contoso.com.pfx NoExport


# 4. Start MMC, Add Certificates Console, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com

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




