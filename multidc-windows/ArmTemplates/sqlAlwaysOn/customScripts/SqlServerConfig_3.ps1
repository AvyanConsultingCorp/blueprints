[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$Domain,
  
  [Parameter(Mandatory=$True)]
  [string]$AppName,

  [Parameter(Mandatory=$True)]
  [string]$ClusterName,
  
  [Parameter(Mandatory=$True)]
  [string]$StaticIp,

  [Parameter(Mandatory=$False)]
  [string]$Step='PRE'
)

$global:ScriptLocation = $PSCommandPath
$global:started = $FALSE
$global:startingStep = $Step
$global:restartKey = "Restart-And-Resume"
$global:RegRunKey ="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$global:powershell = (Join-Path $env:windir "system32\WindowsPowerShell\v1.0\powershell.exe")

Import-Module "sqlps" -DisableNameChecking

$Sql1ServerName = "$AppName-sql-1"
$Sql2ServerName = "$AppName-sql-2"

# -------------------------------------
# Collection of Utility functions.
# -------------------------------------
function Run-Step([string] $prospectStep) 
{
	if ($global:startingStep -eq $prospectStep -or $global:started) {
		$global:started = $True
	}
	
	return $global:started
}

function Test-Key([string] $path, [string] $key)
{
    return ((Test-Path $path) -and ((Get-Key $path $key) -ne $null))   
}

function Remove-Key([string] $path, [string] $key)
{
	Remove-ItemProperty -path $path -name $key
}

function Set-Key([string] $path, [string] $key, [string] $value) 
{
	Set-ItemProperty -path $path -name $key -value $value
}

function Get-Key([string] $path, [string] $key) 
{
	return (Get-ItemProperty $path).$key
}

function Restart-And-Run([string] $key, [string] $run) 
{
	Set-Key $global:RegRunKey $key $run
	Restart-Computer -Force
	exit
} 

function Clear-Any-Restart([string] $key=$global:restartKey) 
{
	if (Test-Key $global:RegRunKey $key) {
		Remove-Key $global:RegRunKey $key
	}
}

function Restart-And-Resume([string] $script, [string] $step) 
{
	Restart-And-Run $global:restartKey "$global:powershell -ExecutionPolicy Unrestricted $script -Domain $Domain -AdminUser $AdminUser -AdminPassword $AdminPassword -AppName $AppName -ClusterName $ClusterName -StaticIp $StaticIp -Step $step"
}

#endregion

#Region "Main Calling Function"

function Restart-Call($cutomOutput)
{
	Clear-Any-Restart
	if (Run-Step "PRE") 
	{
		CustomPreRestartActions $cutomOutput			
		Restart-And-Resume $global:ScriptLocation "POST"		
	}

	if (Run-Step "POST") 
	{
		CustomRestartActions $cutomOutput		
	}
}

function CustomPreRestartActions([string]$outputStr="Empty")
{
	Write-Host $outputStr + ": Joining the computer to the domain..."
      
    # Join domain
    $secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $secAdminPassword)	
	Add-Computer -Credential $credential -DomainName $Domain -Force
    Write-Host $outputStr + ": Adding domain user to SQL server..."
   
    # Add domain user
    Add-DomainUser $AdminUser $AdminPassword
   
    Write-Host $outputStr + ": Creating failover cluster and configuring AlwaysOn..."

    # Install cluster
    Install-FailoverCluster

    # Configure SQL AlwaysOn
    Configure-AlwaysOn
}

function CustomRestartActions([string]$outputStr="Empty")
{

}

#endregion

function Add-DomainUser([string]$user, [string]$adminPwd)
{
    Write-Host 'Invoked Add-DomainUser with: ' $user
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server '(local)'
    $sqlUser = New-Object Microsoft.SqlServer.Management.Smo.Login($server, $user)
    $sqlUser.LoginType = "WindowsUser"
    $sqlUser.create($adminPwd)
    $sqlUser.AddToRole("sysadmin")
}

function Install-FailoverCluster
{
    Write-Host 'Install-FailoverCluster'
    Install-WindowsFeature -Name FailOver-Clustering -IncludeManagementTools
    Install-WindowsFeature -ComputerName $Sql2ServerName -Name FailOver-Clustering -IncludeManagementTools
    $cluster = New-Cluster -Name $ClusterName -StaticAddress $StaticIp -Node $Sql1ServerName,$Sql2ServerName -NoStorage
    Set-ClusterQuorum -InputObject $cluster -FileShareWitness "\\$AppName-fsw\$ClusterName"
}

function Configure-AlwaysOn
{
    $sql1 = new-Object Microsoft.SqlServer.Management.Smo.Server($Sql1ServerName)
    $sql2 = new-Object Microsoft.SqlServer.Management.Smo.Server($Sql2ServerName)

    # Create a database, to join to the availability group
    $db = New-Object Microsoft.SqlServer.Management.Smo.Database($sql1, "TestDb")
    $db.Create()

    $servers = @($Sql1ServerName, $Sql2ServerName)
    foreach($sqlServer in $servers)
    {
        # Change SQL service log on. This allows MSSQLSERVER to access the file share
        Change-SqlLogon $sqlServer
        
        # Enable AlwaysOn
        Enable-SqlAlwaysOn -ServerInstance $sqlServer

        # Set firewall rules and open ports
        Set-FirewallRule $sqlServer
    }

    # Back up database to a file share that both SQL server instances can access, and restore to sql2
    Backup-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\$ClusterName\db.bak" -ServerInstance $Sql1ServerName
    Backup-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\$ClusterName\db.log" -ServerInstance $Sql1ServerName -BackupAction Log 
    Restore-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\$ClusterName\db.bak" -ServerInstance $Sql2ServerName -NoRecovery
    Restore-SqlDatabase -Database "TestDb" -BackupFile "\\$AppName-fsw\$ClusterName\db.log" -ServerInstance $Sql2ServerName -NoRecovery -RestoreAction Log

    # Create AGs
    Create-AvailabilityGroup
}

function Set-FirewallRule([string]$sqlServer)
{
    $cim = New-CimSession -ComputerName $sqlServer
    New-NetFirewallRule -DisplayName "SQL AlwaysOn: DB Mirror" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 5022 -CimSession $cim
    New-NetFirewallRule -DisplayName "SQL Server" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 1433 -CimSession $cim
    New-NetFirewallRule -DisplayName "SQL AlwaysOn: Listener Probe" -Action "Allow" -Direction "Inbound" -Protocol TCP -LocalPort 59999 -CimSession $cim
    Remove-CimSession -CimSession $cim
}

function Change-SqlLogon([string]$sqlServer)
{
    $mc = new-object Microsoft.SQLServer.Management.SMO.WMI.ManagedComputer $sqlServer
    $service = $mc.Services['MSSQLSERVER']
    $service.SetServiceAccount($AdminUser, $AdminPassword)
    #$service.Stop()
    #$service.Refresh()
    #$service.Start()
}

function Create-AvailabilityGroup
{
    $primaryUri = "tcp://$Sql1ServerName.$Domain:5022"
    $primary = New-SqlAvailabilityReplica -Name $Sql1ServerName -EndpointUrl $primaryUrl -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate

    $secondaryUri = "tcp://$Sql2ServerName.$Domain:5022"
    $secondary = New-SqlAvailabilityReplica -Name $Sql2ServerName -EndpointUrl $secondaryUrl -AvailabilityMode "SynchronousCommit" -FailoverMode "Automatic" -Version 12 -AsTemplate

    New-SqlAvailabilityGroup -Name "sqlAg007" -Path "SQLSERVER:\SQL\$Sql1ServerName\DEFAULT" -AvailabilityReplica @($primary, $secondary) -Database "TestDb"
    Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$Sql2ServerName\DEFAULT" -Name "sqlAg007"
    Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\$Sql2ServerName\DEFAULT\AvailabilityGroups\sqlAg007" -Database "TestDb"
    New-SqlAvailabilityGroupListener -Name "listener1" -StaticIp '$StaticIp/255.255.255.0' -Path "SQLSERVER:\sql\$Sql1ServerName\DEFAULT\AvailabilityGroups\sqlAg007"
}


Restart-Call "Configuring SQL Server AlwaysOn feature using a scheduled restart job"