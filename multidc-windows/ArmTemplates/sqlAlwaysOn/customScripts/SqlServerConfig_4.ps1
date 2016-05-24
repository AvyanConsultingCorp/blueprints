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

    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $env:ComputerName
    $conn.ServerInstance = "(local)"
    $conn.Connect()
    $smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn
    $SqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $smo,"${env:ComputerName}\$user"
    $SqlUser.LoginType = 'WindowsUser'
    $SqlUser.Create($adminPwd)
    $SqlUser.AddToRole("sysadmin")
}

# Add domain user to SQL server
Add-DomainUser $AdminUser $AdminPassword

# Join domain
$domainUser = "$Domain\$AdminUser"
$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($domainUser, $secAdminPassword)
Add-Computer -Credential $credential -DomainName $Domain -Force
Restart-Computer -Force
