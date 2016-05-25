[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$Domain,

  [Parameter(Mandatory=$True)]
  [string]$ClusterName,
  
  [Parameter(Mandatory=$False)]
  [string]$Step='PRE'
)

$global:ScriptLocation = $PSCommandPath
$global:started = $FALSE
$global:startingStep = $Step
$global:restartKey = "Restart-And-Resume"
$global:RegRunKey ="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$global:powershell = (Join-Path $env:windir "system32\WindowsPowerShell\v1.0\powershell.exe")

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
	Restart-And-Run $global:restartKey "$global:powershell -ExecutionPolicy Unrestricted $script -Domain $Domain -AdminUser $AdminUser -AdminPassword $AdminPassword -ClusterName $ClusterName -Step $step"
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
	Add-Computer -Credential $credential -DomainName $Domain -Force -Restart
}

function CustomRestartActions([string]$outputStr="Empty")
{
   	Write-Host $outputStr + ": Initalizing and formatting disks..."
    
    Format-Drive F
    Create-FileShare 'F:'
}

function Format-Drive([string]$driveLetter='F')
{
    # Format F: drive
	Initialize-Disk -Number 2
	New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter $driveLetter
	Format-Volume -DriveLetter $driveLetter -Force

}

function Create-FileShare([string]$driveLetter='F:')
{
    # Create new share
    $clusterShare = Join-Path $driveLetter $ClusterName
	New-Item $clusterShare -ItemType directory
	New-SmbShare -Name $ClusterName -Path $clusterShare -FullAccess Administrators
}

#endregion

Restart-Call "Configuring File Share Witness with scheduled restart job!"
