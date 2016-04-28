[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$SafeModePassword,

  [Parameter(Mandatory=$True)]
  [string]$Domain
)

Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-windowsfeature -name DNS -IncludeAllSubFeature -IncludeManagementTools
$secPwd = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
Install-ADDSForest -DomainName $Domain -InstallDNS -SafeModeAdministratorPassword $secPwd
