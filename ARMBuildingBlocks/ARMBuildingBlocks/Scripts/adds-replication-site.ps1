[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

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

#  $AdminUser = "adminUser"
#  $AdminPassword = "adminP@ssw0rd"
#  $DomainName = "contoso.com"
#  $SiteName="AzureAdSite"
#  $Cidr = "10.0.0.0/16"
#  $ReplicationFrequency = 5
$Description="azure vnet ad site"
$Location="azure subnet location"
$SitelinkName = "AzureToOnpremLink"
$OnpreSite= "Default-First-Site-Name"

Install-windowsfeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools

Import-Module ADDSDeployment

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$AdminUser", $secAdminPassword)

New-ADReplicationSite -Name $SiteName -Description $Description -Credential $credential 

New-ADReplicationSubnet -Name $Cidr -Site $SiteName -Location $location -Credential $credential 

New-ADReplicationSiteLink `
-Credential $credential `
-Name $SitelinkName `
-SitesIncluded $OnpreSite, $SiteName `
-Cost 100 `
-ReplicationFrequency $ReplicationFrequency `
-InterSiteTransportProtocol IP
