Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName 'Pnp Azure'

#############################################################################
# Make sure that the following parameters match the ones in the template

$resourceGroupName='app-6-rg'
$deploymentName='app-6-rg-dep'
$location='West US'

$vnetName='app6-vnet'
$subnetName='app6-web-sn'
$avsetName='app6-web-avSet'

$vnetAddressPrefix='10.4.0.0/16'
$subnetAddressPrefix='10.4.0.0/24'

# Create new resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Set subnet config
$subNet=New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix

# Create a new VNet
New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -AddressPrefix $vnetAddressPrefix  -Location $location -Subnet $subNet

# Create a new availability set
New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $avsetName -Location $location -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 3


# Template and first parameter file URIs
$templateUri = 'https://raw.githubusercontent.com/mspnp/blueprints/refarch/buildingblocks/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-n-vm-n-nic/azuredeploy.json'
$templateParamUri = 'https://raw.githubusercontent.com/mspnp/blueprints/refarch/buildingblocks/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-n-vm-n-nic/azuredeploy.parameters.json'

Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri -Verbose
