Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId 'a012a8b0-522a-4f59-81b6-aa0361eb9387'

#############################################################################
# Deploy infrastructure in first region

$firstResourceGroupName='a0-rg'
$firstDeploymentName='a0-rg-dep'
$location1='West US' # First region to deploy into (see regional pairing for optimum selection)

# Create new resource group
New-AzureRmResourceGroup -Name $firstResourceGroupName -Location $location1

# Template and first parameter file URIs
$templateUri = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-vnet.json'
$templateParamUri1 = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-vnet.v1.param.json'

$result = Test-AzureRmResourceGroupDeployment -ResourceGroupName $firstResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri1

# Test-AzureRmResourceGroupDeployment returns a list of PSResourceManagerError objects, so a count of 0 is all clear signal!
if($result.Count -eq 0){
	New-AzureRmResourceGroupDeployment -Name $firstDeploymentName -ResourceGroupName $firstResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri1 -Verbose
}else{
    $result
}

#############################################################################
# Deploy infrastructure in second region

$secondResourceGroupName='app-2-rg'
$secondDeploymentName='app-2-rg-dep'
$location2='East US' # Second region to deploy into (see regional pairing for optimum selection)

# Create new resource group
New-AzureRmResourceGroup -Name $secondResourceGroupName -Location $location2

# Second parameter file URI
$templateParamUri2 = "https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-vnet.v2.param.json"

New-AzureRmResourceGroupDeployment -Name $secondDeploymentName -ResourceGroupName $secondResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri2 -Verbose

##############################################################################
# Establish gateway VPN connections

# Connection names
$firstConnection = 'Vnet1-to-Vnet2'
$secondConnection = 'Vnet2-to-Vnet1'

# Create the connections between first and the second gateway. Make sure that the gateway name matches the one specified in parameter file for each deployment.
$vnetGateway1 = Get-AzureRmVirtualNetworkGateway -Name v1-gateway -ResourceGroupName $firstResourceGroupName

$vnetGateway2 = Get-AzureRmVirtualNetworkGateway -Name v2-gateway -ResourceGroupName $secondResourceGroupName

# Read the shared key from console
$sharedKey =  Read-Host 'Enter your shared key'

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
