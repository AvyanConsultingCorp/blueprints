Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$GmsaName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName

)

# $AdminUser = "adminUser"
# $AdminPassword = "adminP@ssw0rd"
# $NetBiosDomainName = "CONTOSO"
# $GmsaName = "adfsgmsa"
# $FederationName = "adfs.contoso.com"

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)
Add-KdsRootKey –EffectiveTime (Get-Date).AddHours(-10) 
#New-ADServiceAccount adfsgmsa -DNSHostName adfs.contoso.com -AccountExpirationDate $null -ServicePrincipalNames host/adfs.contoso.com -Credential $credential
New-ADServiceAccount $GmsaName -DNSHostName $FederationName -AccountExpirationDate $null -ServicePrincipalNames "host/$FederationName" -Credential $credential
