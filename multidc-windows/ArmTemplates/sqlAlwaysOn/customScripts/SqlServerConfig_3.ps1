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
  [string]$AppName,

  [Parameter(Mandatory=$True)]
  [string]$ClusterName,
  
  [Parameter(Mandatory=$True)]
  [string]$StaticIp,
)

Import-Module "sqlps" -DisableNameChecking

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server "(local)"
$SqlUser = New-Object Microsoft.SqlServer.Management.Smo.Login($srv, $AdminUser)
$SqlUser.LoginType = "WindowsUser"
$SqlUser.create($AdminPassword)
$sqlUser.AddToRole("sysadmin")

$secSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $secAdminPassword)

Enable-PSRemoting -Force

Install-WindowsFeature -Name FailOver-Clustering -IncludeManagementTools

Install-WindowsFeature -ComputerName "$AppName-sql-2" -Name FailOver-Clustering -IncludeManagementTools

$cluster = New-Cluster -Name $ClusterName -StaticAddress $StaticIp -Node "$AppName-sql-1","$AppName-sql-2" -NoStorage
Set-ClusterQuorum -InputObject $cluster -FileShareWitness "\\$AppName-fsw\cluster1-fsw"

$Sql1ServerName = "$AppName-sql-1"
$Sql2ServerName = "$AppName-sql-2"

$sql1 = new-Object Microsoft.SqlServer.Management.Smo.Server($Sql1ServerName)
$sql2 = new-Object Microsoft.SqlServer.Management.Smo.Server($Sql2ServerName)

# Create a database, to join to the availability group
$db = New-Object Microsoft.SqlServer.Management.Smo.Database($sql1, "TestDb")
$db.Create()

# Change SQL service log on.
# This allows MSSQLSERVER to access the file share
$mc = new-object Microsoft.SQLServer.Management.SMO.WMI.ManagedComputer $Sql1ServerName
$service = $mc.Services["MSSQLSERVER"]
$service.SetServiceAccount("$Domain\sqladmin", $AdminPassword)
#$service.Stop()
#$service.Refresh()
#$service.Start()

$mc = new-object Microsoft.SQLServer.Management.SMO.WMI.ManagedComputer $Sql2ServerName
$service = $mc.Services["MSSQLSERVER"]
$service.SetServiceAccount("$Domain\sqladmin", $AdminPassword)
#$service.Stop()
#$service.Refresh()
#$service.Start()

Enable-SqlAlwaysOn -ServerInstance $Sql1ServerName 
Enable-SqlAlwaysOn -ServerInstance $Sql2ServerName 


# Open ports on SQL1
New-NetFirewallRule -DisplayName "SQL AlwaysOn: DB Mirror" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 5022 
New-NetFirewallRule -DisplayName "SQL Server" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 1433 
New-NetFirewallRule -DisplayName "SQL AlwaysOn: Listener Probe" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 59999 

# Open ports on SQL2
$cim = New-CimSession -ComputerName $Sql2ServerName
New-NetFirewallRule -DisplayName "SQL AlwaysOn: DB Mirror" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 5022 -CimSession $cim
New-NetFirewallRule -DisplayName "SQL Server" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 1433 -CimSession $cim
New-NetFirewallRule -DisplayName "SQL AlwaysOn: Listener Probe" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 59999 -CimSession $cim


# Back up database to a file share that both SQL server instances can access, and restore to sql2
Backup-SqlDatabase -Database "TestDB" -BackupFile "\\$AppName-fsw\cluster1-fsw\db.bak" -ServerInstance $Sql1ServerName
Backup-SqlDatabase -Database "TestDB" -BackupFile "\\$AppName-fsw\cluster1-fsw\db.log" -ServerInstance $Sql1ServerName -BackupAction Log 
Restore-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\cluster1-fsw\db.bak" -ServerInstance $Sql2ServerName -NoRecovery
Restore-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\cluster1-fsw\db.log" -ServerInstance $Sql2ServerName -NoRecovery -RestoreAction Log


# Create the availability group


$primaryUrl = "tcp://$Sql1ServerName."+$Domain+":5022"
$secondaryUrl = "tcp://$Sql2ServerName."+$Domain+":5022"


$primary = New-SqlAvailabilityReplica -Name $Sql1ServerName -EndpointUrl $primaryUrl -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate

$secondary = New-SqlAvailabilityReplica -Name $Sql2ServerName -EndpointUrl $secondaryUrl -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate


# TODO can get version from the instance

New-SqlAvailabilityGroup -Name "ag1" -Path "SQLSERVER:\SQL\$Sql1ServerName\DEFAULT" -AvailabilityReplica @($primary, $secondary) -Database "TestDb"
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$Sql2ServerName\DEFAULT" -Name "ag1"
Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\$Sql2ServerName\DEFAULT\AvailabilityGroups\ag1" -Database "TestDb"
New-SqlAvailabilityGroupListener -Name "listener1" -StaticIp '$StaticIp/255.255.255.0' -Path SQLSERVER:\sql\$Sql1ServerName\DEFAULT\AvailabilityGroups\ag1

# Join domain
Add-Computer -Credential $credential -DomainName $Domain -Force -Restart