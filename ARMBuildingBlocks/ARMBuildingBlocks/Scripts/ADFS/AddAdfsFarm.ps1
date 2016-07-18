Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$DomainName,

   [Parameter(Mandatory=$True)]
  [string]$PrimaryFqName,

  [Parameter(Mandatory=$True)]
  [string]$GmsaAdfs,

   [Parameter(Mandatory=$True)]
  [string]$FqDomainName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName

)
# domainjoin script needs to be executed first

Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
Import-Module ADFS

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)


# code has to come here to get the certificate from keyfault. It needs to run under arm template
# because of security requirements Oauth flow to AAD
# we saved it on disk
# install the certificate on local machine store

# certutil.exe -privatekey -p passw0rd -importPFX my adfs-cert

# the thumbnail of certificate is retrieved

$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

# here if we want to test the deployment is a good practice

#Test-AdfsFarmJoin -CertificateThumbprint $thumbprint -PrimaryComputerName $PrimaryFqName -GroupServiceAccountIdentifier "$DomainName\$GmsaAdfs`$" -Credential $credential
Add-AdfsFarmNode  -CertificateThumbprint $thumbprint -PrimaryComputerName $PrimaryFqName -GroupServiceAccountIdentifier "$DomainName\$GmsaAdfs`$" -Credential $credential

#------------------------------------------------------------------------------

# device registration service for workplace join 
Initialize-ADDeviceRegistration -ServiceAccountName "$DomainName\$GmsaAdfs`$" -DeviceLocation $FqDomainName -RegistrationQuota 10 -MaximumRegistrationInactivityPeriod 90 -Credential $Credential -Force
Enable-AdfsDeviceRegistration -Credential $Credential -Force



