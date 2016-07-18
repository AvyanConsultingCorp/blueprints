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
  [string]$descriptionAdfs


)
# domainjoin script needs to be executed first
# example of command
#.\AddAdfsFarm.ps1 -AdminUser "domainuser" -AdminPassword "domainPass" -NetBiosDomainName "patterns2" -FqDomainName "patternspractices.net" -GmsaAdfs "adfsacct" -FederationName "pnpadfs.patternspractices.net" -descriptionAdfs "PNP ADFS"

Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
Import-Module ADFS

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

#----GMSA under which ADFS service runs under-------------------------------------

Add-KdsRootKey –EffectiveTime (Get-Date).AddHours(-10) 

New-ADServiceAccount $GmsaAdfs -DNSHostName "$GmsaAdfs.$FqDomainName" -AccountExpirationDate $null -ServicePrincipalNames "http://$GmsaAdfs.$FqDomainName" -Credential $credential

#------------------------------------------------------------------------------

# code has to come here to get the certificate from keyfault. It needs to run under arm template
# because of security requirements Oauth flow to AAD
# we saved it on disk
# install the certificate on local machine store

#certutil.exe -privatekey -p "Pag`$some" -importPFX my C:\certificates\pnpadfsfinal.pfx NoExport
# the thumbnail of certificate is retrieved

$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

# here if we want to test the deployment is a good practice

#Test-AdfsFarmInstallation -CertificateThumbprint $thumbprint -FederationServiceDisplayName $federationName -FederationServiceName $federationName -GroupServiceAccountIdentifier "patterns\pnpacct`$" -Credential $credential

#Write-Host "$NetBiosDomainName\$GmsaAdfs`$"

Install-AdfsFarm  -CertificateThumbprint $thumbprint -FederationServiceDisplayName $descriptionAdfs -FederationServiceName $FederationName -GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaAdfs`$" -Credential $credential -OverwriteConfiguration


#Install-AdfsFarm  -CertificateThumbprint $thumbprint `
#-FederationServiceDisplayName $descriptionAdfs `
#-FederationServiceName $FederationName ` 
#-GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaAdfs`$" `
#-Credential $credential -OverwriteConfiguration

#------------------------------------------------------------------------------

# device registration service for workplace join 
Initialize-ADDeviceRegistration -ServiceAccountName "$NetBiosDomainName\$GmsaAdfs`$" `
-DeviceLocation $FqDomainName `
-RegistrationQuota 10 `
-MaximumRegistrationInactivityPeriod 90 `
-Credential $Credential -Force

Enable-AdfsDeviceRegistration -Credential $Credential -Force



