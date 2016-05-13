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
#Install-ADDSForest -DomainName $Domain -InstallDNS -SafeModeAdministratorPassword $secPwd -Force
Install-ADDSForest -DatabasePath "%SYSTEMROOT%\NTDS" -DomainName $Domain -SysvolPath "%SYSTEMROOT%\SYSVOL" -LogPath "%SYSTEMROOT%\NTDS" -SafeModeAdministratorPassword $secPwd -NoRebootOnCompletion -Force

Restart-Computer -Force