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

function Add-DomainUser([string]$user, [string]$adminPwd)
{
    Write-Host 'Invoked Add-DomainUser with: ' $user
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server '(local)'
    $sqlUser = New-Object Microsoft.SqlServer.Management.Smo.Login($server, $user)
    $sqlUser.LoginType = "WindowsUser"
    $sqlUser.create($adminPwd)
    $sqlUser.AddToRole("sysadmin")
}

# Add domain user to SQL server
Add-DomainUser $AdminUser $AdminPassword

# Join domain
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $secAdminPassword)
Add-Computer -Credential $credential -DomainName $Domain -Force
Restart-Computer -Force
