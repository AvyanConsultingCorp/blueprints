Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

   [Parameter(Mandatory=$True)]
  [string]$FqDomainName,

  [Parameter(Mandatory=$True)]
  [string]$GmsaAdfs,

  [Parameter(Mandatory=$True)]
  [string]$FederationName,

  [Parameter(Mandatory=$True)]
  [string]$DescriptionAdfs
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
#    a certificate for myadfs.contoso.com and enterpriseregistration.contoso.com
#
# makecert -sk pkey -iv MyFakeRootCertificateAuthority.pvk -a sha256 -n "CN=*.contoso.com" -ic MyFakeRootCertificateAuthority.cer -sr localmachine -ss my -sky exchange -pe
# makecert -sk pkey -iv MyFakeRootCertificateAuthority.pvk -a sha256 -n "CN=adfs1.contoso.com , CN=enterpriseregistration.contoso.com" -ic MyFakeRootCertificateAuthority.cer -sr localmachine -ss my -sky exchange -pe
# makecert -sk pkey -iv MyFakeRootCertificateAuthority.pvk -a sha256 -n "CN=adfs.contoso.com , CN=enterpriseregistration.contoso.com" -ic MyFakeRootCertificateAuthority.cer -sr localmachine -ss my -sky exchange -pe

# 5. start mmc certificates console 
#	Expand to /Certificates (Local Computer)/Personal/Certificate/*.contoso.com 
#	Expand to /Certificates (Local Computer)/Personal/Certificate/adfs1.contoso.com 
#
#	Export the certificate with the private key to 
#    C:/temp/contosocom.pfx
#    C:/temp/adfscontosocom.pfx
#    C:/temp/adfs1contosocom.pfx

# 6. Make sure you have the following files in the C:\temp
#	 MyFakeRootCertificateAuthority.cer
#	 MyFakeRootCertificateAuthority.pvk
#    contosocom.pfx
#    adfscontosocom.pfx
#    adfs1contosocom.pfx

###################

# 7. RDP to the each ADFS VM.

# 8. copy 
#		certutil.exe
#		MyFakeRootCertificateAuthority.cer
#       contosocom.pfx
#       adfscontosocom.pfx
#       adfs1contosocom.pfx
#    to 
#		C:\temp\ 

# 9. Run the following command prompt as admin:
#	    certutil.exe -addstore "Root" "C:\temp\MyFakeRootCertificateAuthority.cer"
#   Open mmc Certificate Console and verify that it now has the following item
#      \Certificates (Local Computer)\Trusted Root Certification Authorities\Certificates\MyFakeRootCertificateAuthority 

# 10. Run the following command prompt as admin:
#  		certutil.exe -privatekey -importPFX my C:\temp\contosocom.pfx NoExport
#  		certutil.exe -privatekey -importPFX my C:\temp\adfscontosocom.pfx NoExport
#  		certutil.exe -privatekey -importPFX my C:\temp\adfs1contosocom.pfx NoExport
#   Open mmc Certificate Console and verify that it now has the following item
#      \Certificates (Local Computer)\Personal\Certificates\*.contoso.com issued by MyFakeRootCertificationAuthority 
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com issued by MyFakeRootCertificationAuthority 
#      \Certificates (Local Computer)\Personal\Certificates\adfs1.contoso.com issued by MyFakeRootCertificationAuthority 

# 11. Repeat step 7 to 10 for next ADDS server

###############################################
# Manual steps if you have a public signed certificate adfs.contoso.com.pfx by VerifSign, Go Daddy, DigiCert, and etc.

# 1. RDP to the each ADFS VM.

# 2. copy 
#		certutil.exe
#		adfs.contoso.com.pfx 
#    to 
#		C:\temp\ 

# 10. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\adfs.contoso.com.pfx NoExport
#   Open mmc Certificate Console and verify that it now has the following item
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com issued by A Real Certification Authority


# $AdminUser = "adminUser"
# $AdminPassword = "adminP@ssw0rd"
# $NetBiosDomainName = "CONTOSO"
# $FqDomainName = "contoso.com"
# $GmsaAdfs = "adfsservice"
# $FederationName = "adfs.contoso.com"
# $DescriptionAdfs = "Contoso Corporation"

###############################################
# domainjoin script needs to be executed first

# retrieve the the thumbnail of certificate
#$thumbprint=(Get-ChildItem -DnsName *.$FqDomainName -Path cert:\LocalMachine\My).Thumbprint
$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint
Write-Host $thumbprint

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

# Create GMSA under which ADFS service runs under
Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Import-Module ADDSDeployment
New-ADServiceAccount $GmsaAdfs -DNSHostName "$GmsaAdfs.$FqDomainName" -AccountExpirationDate $null -ServicePrincipalNames "http://$GmsaAdfs.$FqDomainName" -Credential $credential
setspn -a host/$FederationName $GmsaAdfs

# Install ADFS feature
Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
Import-Module ADFS
Add-KdsRootKey –EffectiveTime (Get-Date).AddHours(-10) 
Install-AdfsFarm  -CertificateThumbprint $thumbprint -FederationServiceDisplayName $DescriptionAdfs -FederationServiceName $FederationName -GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaAdfs`$" -Credential $credential -OverwriteConfiguration

# device registration service for workplace join 
Initialize-ADDeviceRegistration -ServiceAccountName "$NetBiosDomainName\$GmsaAdfs`$" -DeviceLocation $FqDomainName -RegistrationQuota 10 -MaximumRegistrationInactivityPeriod 90 -Credential $Credential -Force
Enable-AdfsDeviceRegistration -Credential $Credential -Force

Restart-Computer
