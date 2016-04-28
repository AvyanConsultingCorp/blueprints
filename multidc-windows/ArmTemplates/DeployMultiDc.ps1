Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName 'Pnp Azure'

# Change the location accordingly - supported values may be obtained using REST call below:
# https://management.core.windows.net/<subscription-id>/locations


# Omit the below step if you are using an existing resource group

#############################################################################
# First template

$firstResourceGroupName='multidc-1-rg'
$firstDeploymentName='multidc-1-rg-dep'
$location1='West US' 
$firstConnection = 'Vnet1-to-Vnet2'

New-AzureRmResourceGroup -Name $firstResourceGroupName -Location $location1

$templatePath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureFirstVnet.json"
$templateParamPath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureFirstVnet.param.dev.json"

Test-AzureRmResourceGroupDeployment -ResourceGroupName $firstResourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName $firstResourceGroupName -Name $firstDeploymentName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
#############################################################################


#############################################################################
# Second template

$secondResourceGroupName='multidc-2-rg'
$secondDeploymentName='multidc-2-rg-dep'
$location2='East US'
$secondConnection = 'Vnet2-to-Vnet1'

New-AzureRmResourceGroup -Name $secondResourceGroupName -Location $location2

$templatePath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureSecondVnet.json"
$templateParamPath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureSecondVnet.param.dev.json"

Test-AzureRmResourceGroupDeployment -ResourceGroupName $secondResourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName $secondResourceGroupName -Name $secondDeploymentName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
##############################################################################

#Get-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName

Get-AzureRmResourceGroupDeploymentOperation -DeploymentName $secondDeploymentName -ResourceGroupName $secondResourceGroupName -Verbose

(Get-AzureRmLog -ResourceGroup $secondResourceGroupName -StartTime (Get-Date).AddDays(-3) -Status Failed -DetailedOutput).Properties[1].Content["statusMessage"] | ConvertFrom-Json

#############################################################################
# Create the connections between first and the second gateway here
$vnetGateway1 = Get-AzureRmVirtualNetworkGateway -Name first-vnet-gateway -ResourceGroupName $firstResourceGroupName
($vnetGateway1).IpConfigurationsText | Write-Host
($vnetGateway1).Id | Write-Host

$vnetGateway2 = Get-AzureRmVirtualNetworkGateway -Name second-vnet-gateway -ResourceGroupName $secondResourceGroupName
$sharedKey =  'QAZwsx123' #Read-Host 'Enter your shared key' -AsSecureString

# Vnet 1 to Vnet 2
New-AzureRmVirtualNetworkGatewayConnection -Name $firstConnection -ResourceGroupName $firstResourceGroupName -VirtualNetworkGateway1 $vnetGateway1 -VirtualNetworkGateway2 $vnetGateway2 -Location $location1 -ConnectionType Vnet2Vnet -SharedKey $sharedKey

# Vnet 2 to Vnet 1
New-AzureRmVirtualNetworkGatewayConnection -Name $secondConnection -ResourceGroupName $secondResourceGroupName -VirtualNetworkGateway1 $vnetGateway2 -VirtualNetworkGateway2 $vnetGateway1 -Location $location2 -ConnectionType Vnet2Vnet -SharedKey $sharedKey
#############################################################################

# Third template

$tmResourceGroupName='multidc-tm'
$tmDeploymentName='multidc-tm-dep'
$location3='Central US'

New-AzureRmResourceGroup -Name $tmResourceGroupName -Location $location3

$templatePath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureTrafficManager.json"
$templateParamPath = "C:\Dev12\Projects\Workbench\Blueprints\MultiDc\MultiDcDeploy\MultiDcDeploy\Templates\ConfigureTrafficManager.param.dev.json"

Test-AzureRmResourceGroupDeployment -ResourceGroupName $tmResourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName $tmResourceGroupName -Name $tmDeploymentName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose


