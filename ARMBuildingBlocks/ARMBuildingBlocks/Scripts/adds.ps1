[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$SafeModePassword,

  [Parameter(Mandatory=$True)]
  [string]$DomainName,

  [Parameter(Mandatory=$True)]
  [string]$SiteName,

  [Parameter(Mandatory=$True)]
  [string]$Cidr,

  #Replication Frequency in minutes
  [Parameter(Mandatory=$True)]
  [int]$ReplicationFrequency
)

$Description="azure vnet ad site"
$Location="azure subnet location"
#  $AdminUser = "adminUser"
#  $AdminPassword = "adminP@ssw0rd"
#  $SafeModePassword = "SafeModeP@ssw0rd"
#  $DomainName = "contoso.com"
#  $SiteName="AzureAdSite"
#  $Cidr = "10.0.0.0/16"
#  $ReplicationFrequency = 5
$SitelinkName = "Azure Vnet To On Prem Link"
$SitesIncluded = "Default-First-Site-Name,$SiteName"


Initialize-Disk -Number 2 -PartitionStyle GPT
New-Partition -UseMaximumSize -DriveLetter F -DiskNumber 2
Format-Volume -DriveLetter F -Confirm:$false -FileSystem NTFS -force 

Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools

Import-Module ADDSDeployment

New-ADReplicationSite -Name $SiteName -Description $Description 

New-ADReplicationSubnet -Name $Cidr -Site $SiteName -Location $location 

New-ADReplicationSiteLink `
-Name $SitelinkName `
-SitesIncluded $SitesIncluded `
-Cost 100 `
-ReplicationFrequency $ReplicationFrequency `
-InterSiteTransportProtocol IP

$secSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)

#Install-ADDSDomainController -DomainName $DomainName -Credential $credential –InstallDns -SafeModeAdministratorPassword $secSafeModePassword -Force
#Test-ADDSDomainControllerInstallation `
Install-ADDSDomainController `
-SiteName $Sitename `
-Credential $credential `
-SafeModeAdministratorPassword $secSafeModePassword `
-DomainName $DomainName `
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