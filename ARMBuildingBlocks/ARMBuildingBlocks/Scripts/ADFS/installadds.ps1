[CmdletBinding()]
Param(

  [Parameter(Mandatory=$True)]
  [string]$DomainPassword,

  [Parameter(Mandatory=$True)]
  [string]$nebiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$DomainName,

  [Parameter(Mandatory=$True)]
  [string]$SiteName

)


#./installadds.ps1 -DomainPassword "domainPassword" -nebiosDomainName "patterns2" -DomainName "patternspractices.net" -SiteName "addssite" 
#  $AdminUser = "user"
#  $AdminPassword = "adminP@ssw0rd"
#  $SafeModePassword = "SafeModeP@ssw0rd"
#  $DomainName = "contoso.com"
#  $SiteName="AzureAdSite"

$secSafeModePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)

Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-ADDSForest  -DomainName $DomainName `
-DomainMode Win2012R2 `
-DomainNetbiosName $nebiosDomainName `
-ForestMode Win2012R2 `
-SafeModeAdministratorPassword $secSafeModePassword `
-InstallDns $True `
-SkipPreChecks
