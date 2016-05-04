[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$SafeModePassword,

  [Parameter(Mandatory=$True)]
  [string]$Domain
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

#Enable-PSRemoting -Force

# Join domain
Add-Computer -Credential $credential -DomainName $Domain -Force -Restart
