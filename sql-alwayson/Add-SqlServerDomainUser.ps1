[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword
)

Import-Module "sqlps" -DisableNameChecking

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server "(local)"
$SqlUser = New-Object Microsoft.SqlServer.Management.Smo.Login($srv, $AdminUser)
$SqlUser.LoginType = "WindowsUser"
$SqlUser.create($AdminPassword)
$sqlUser.AddToRole("sysadmin")

