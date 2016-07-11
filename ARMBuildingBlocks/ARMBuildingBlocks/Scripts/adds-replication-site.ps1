[CmdletBinding()]
Param(
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

New-ADReplicationSite -Name $SiteName -Description $Description 

New-ADReplicationSubnet -Name $Cidr -Site $SiteName -Location $location 

New-ADReplicationSiteLink `
-Name $SitelinkName `
-SitesIncluded $OnpreSite, $SiteName `
-Cost 100 `
-ReplicationFrequency $ReplicationFrequency `
-InterSiteTransportProtocol IP
