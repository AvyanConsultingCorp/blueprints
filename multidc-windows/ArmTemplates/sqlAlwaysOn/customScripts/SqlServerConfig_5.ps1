[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$SafeModePassword,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$Domain
)

$secSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $secAdminPassword)

#Enable-PSRemoting -Force

# Join domain
Add-Computer -Credential $credential -DomainName $Domain -Force -Restart

# Format F: drive
Initialize-Disk -Number 2
New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -Force

# Create new share
New-Item f:\cluster1-fsw -ItemType directory
New-SmbShare -Name cluster1-fsw -Path F:\cluster1-fsw -FullAccess Administrators




