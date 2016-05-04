Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName 'my-subscription-name'

#############################################################################
# Deploy infrastructure in first region

$firstResourceGroupName='app-1-rg'
$firstDeploymentName='app-1-rg-dep'
$location1='West US' # First region to deploy into (see regional pairing for optimum selection)

# Create new resource group
New-AzureRmResourceGroup -Name $firstResourceGroupName -Location $location1

# Template and parameter files URI
$templateUri = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-first-vnet.json'
$templateParamUri = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-first-vnet.param.json'

# Deploy the first template in first region
New-AzureRmResourceGroupDeployment -Name $firstDeploymentName -ResourceGroupName $firstResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri -Verbose

#############################################################################
# Deploy infrastructure in second region

$secondResourceGroupName='app-2-rg'
$secondDeploymentName='app-2-rg-dep'
$location2='East US' # Second region to deploy into (see regional pairing for optimum selection)

# Create new resource group
New-AzureRmResourceGroup -Name $secondResourceGroupName -Location $location2

# Template and parameter files URI
$templateUri1 = "https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-second-vnet.json"
$templateParamUri1 = "https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-second-vnet.param.json"

New-AzureRmResourceGroupDeployment -Name $secondDeploymentName -ResourceGroupName $secondResourceGroupName -TemplateUri $templateUri1 -TemplateParameterUri $templateParamUri1 -Verbose

##############################################################################
# Establish gateway VPN connections

# Connection names
$firstConnection = 'Vnet1-to-Vnet2'
$secondConnection = 'Vnet2-to-Vnet1'

# Create the connections between first and the second gateway.
$vnetGateway1 = Get-AzureRmVirtualNetworkGateway -Name app1-vnet-gateway -ResourceGroupName $firstResourceGroupName

$vnetGateway2 = Get-AzureRmVirtualNetworkGateway -Name app2-vnet-gateway -ResourceGroupName $secondResourceGroupName

# Read the shared key from console
$sharedKey =  Read-Host 'Enter your shared key' -AsSecureString

# Vnet 1 to Vnet 2
New-AzureRmVirtualNetworkGatewayConnection -Name $firstConnection -ResourceGroupName $firstResourceGroupName -VirtualNetworkGateway1 $vnetGateway1 -VirtualNetworkGateway2 $vnetGateway2 -Location $location1 -ConnectionType Vnet2Vnet -SharedKey $sharedKey

# Vnet 2 to Vnet 1
New-AzureRmVirtualNetworkGatewayConnection -Name $secondConnection -ResourceGroupName $secondResourceGroupName -VirtualNetworkGateway1 $vnetGateway2 -VirtualNetworkGateway2 $vnetGateway1 -Location $location2 -ConnectionType Vnet2Vnet -SharedKey $sharedKey

#############################################################################
# Deploy traffic manager in a third region

$tmResourceGroupName='multidc-tm'
$tmDeploymentName='multidc-tm-dep'
$location3='Central US'

New-AzureRmResourceGroup -Name $tmResourceGroupName -Location $location3

$templateUriTm = "https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-traffic-manager.json"
$templateParamUriTm = "https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-traffic-manager.param.json"

New-AzureRmResourceGroupDeployment -ResourceGroupName $tmResourceGroupName -Name $tmDeploymentName -TemplateUri $templateUriTm -TemplateParameterUri $templateParamUriTm -Verbose
