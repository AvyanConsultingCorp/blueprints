Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$DomainName,

  [Parameter(Mandatory=$True)]
  [string]$fqDomainName
)
#  $AdminUser = "adminUser"
#  $AdminPassword = "adminP@ssw0rd"
#  $DomainName = "contoso.com"
#example of command below
#.\domainjoin.ps1 -AdminUser administrator1 -AdminPassword "password`$some"
# -DomainName patterns2 -fqDomainName patternspractices.net
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)
Add-Computer -DomainName $fqDomainName -Credential $credential
#Restart-Computer



