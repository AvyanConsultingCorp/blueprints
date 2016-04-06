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


// Where to put this?
Install-WindowsFeature -Name FailOver-Clustering -IncludeManagementTools

// Join domain
Add-Computer -Credential $credential -DomainName $Domain -Force 






