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
Install-ADDSForest -DatabasePath "%SYSTEMROOT%\NTDS" -DomainName $Domain -SysvolPath "%SYSTEMROOT%\SYSVOL" -LogPath "%SYSTEMROOT%\NTDS" -SafeModeAdministratorPassword $secPwd -InstallDns -NoRebootOnCompletion:$false -Force
