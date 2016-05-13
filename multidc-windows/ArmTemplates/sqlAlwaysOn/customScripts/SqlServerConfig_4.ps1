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
  [string]$StaticIp
)

Import-Module "sqlps" -DisableNameChecking

$domainUser = "$Domain\$AdminUser"
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server "(local)"
$SqlUser = New-Object Microsoft.SqlServer.Management.Smo.Login($srv, $domainUser)
$SqlUser.LoginType = "WindowsUser"
$SqlUser.create($AdminPassword)
$sqlUser.AddToRole("sysadmin")

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($domainUser, $secAdminPassword)

# Join domain
Add-Computer -Credential $credential -DomainName $Domain -Force
Restart-Computer -Force
