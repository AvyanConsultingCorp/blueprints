Import-Module "sqlps" -DisableNameChecking


$cred = Get-Credential $AdminUser
Enable-SqlAlwaysOn -ServerInstance sql1 -Credentiaql $cred
Enable-SqlAlwaysOn -ServerInstance sql2 -Credentiaql $cred

// Create a database, to join to the availability group
$srv = new-Object Microsoft.SqlServer.Management.Smo.Server("sql1")
$db = New-Object Microsoft.SqlServer.Management.Smo.Database($srv, "TestDb")
$db.Create()


// Change SQL service log on.
// This allows MSSQLSERVER to access the file share
$mc = new-object Microsoft.SQLServer.Management.SMO.WMI.ManagedComputer "sql1"
$service = $mc.Services["MSSQLSERVER"]
$service.SetServiceAccount("contoso.local\testuser", $pwd)
$service.Stop()
$service.Refresh()
$service.Start()

// TODO same thing on SQL2


// Back up database to an file share that both SQL server instances can access
Backup-SqlDatabase -Database "TestDB" -BackupFile "\\fsw\cluster1-fsw\db.bak" -ServerInstance "sql1"
Backup-SqlDatabase -Database "TestDB" -BackupFile "\\fsw\cluster1-fsw\db.log" -ServerInstance "sql1" -BackupAction Log 



// TODO Open port 1433

Restore-SqlDatabase -Database "TestDb" -BackupFile "\\fsw\cluster1-fsw\db.bak" -ServerInstance "sql2" -NoRecover


// Create the availability group

$secondary = New-SqlAvailabilityReplica -Name "sql2" -EndpointUrl "tcp://sql2.contoso.local:5022" `
    -AvaililityMode "AchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate


$primary = New-SqlAvailabilityReplica -Name "sql1" -EndpointUrl "tcp://sql1.contoso.local:5022" `
    -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate

        // BUG can get version from the instance

New-SqlAvailabilityGroup -Name "ag1" -InputObject $srv -AvailabilityReplica @($primary, $secondary) -Database "TestDb"