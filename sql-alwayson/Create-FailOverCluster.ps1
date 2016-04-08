[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AppName,

  [Parameter(Mandatory=$True)]
  [string]$ClusterName
)



Install-WindowsFeature -Name FailOver-Clustering -IncludeManagementTools

Install-WindowsFeature -ComputerName "$AppName-sql-2" -Name FailOver-Clustering -IncludeManagementTools

$cluster = New-Cluster -Name $ClusterName -StaticAddress 10.0.1.25 -Node "$AppName-sql-1","$AppName-sql-2" -NoStorage
Set-ClusterQuorum -InputObject $cluster -FileShareWitness "\\$AppName-fsw\cluster1-fsw"

