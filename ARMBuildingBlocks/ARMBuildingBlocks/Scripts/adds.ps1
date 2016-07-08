[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$SafeModePassword,

  [Parameter(Mandatory=$True)]
  [string]$Domain,

  [Parameter(Mandatory=$True)]
  [string]$SiteName
)

#  $AdminUser = "adminUser"
#  $AdminPassword = "adminP@ssw0rd"
#  $SafeModePassword = "SafeModeP@ssw0rd"
#  $Domain = "contoso.com"
#  $SiteName="AzureAdSite"

Initialize-Disk -Number 2 -PartitionStyle GPT | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -Confirm:$false -FileSystem NTFS -force 

Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools

$secSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ("$Domain\$AdminUser", $secAdminPassword)

Import-Module ADDSDeployment

#New-ADReplicationSite -Name $SiteName -Description "description" -PassThru

#Install-ADDSDomainController -DomainName $Domain -Credential $credential –InstallDns -SafeModeAdministratorPassword $secSafeModePassword -Force
#Test-ADDSDomainControllerInstallation `
Install-ADDSDomainController `
-Credential $credential `
-SafeModeAdministratorPassword $secSafeModePassword `
-DomainName $Domain `
-SiteName $SiteName `
-SysvolPath "F:\Adds\SYSVOL" `
-DatabasePath "F:\Adds\NTDS" `
-LogPath "F:\Adds\NTDS" `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-CriticalReplicationOnly:$false `
-InstallDns:$true `
-NoRebootOnCompletion:$false `
-Force:$true

#$OnpremSiteName = "Default-First-Site-Name"
#New-ADReplicationSiteLink `
#-Name 'sitelinkname' `
#-SitesIncluded $OnpremSiteName,$SiteName `
#-Cost 500 `
#-ReplicationFrequency 240 `
#-InterSiteTransportProtocol IP `
#-PassThru