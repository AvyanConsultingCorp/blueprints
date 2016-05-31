Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName 'Pnp Azure'

#############################################################################
# Deploy infrastructure in first region

$firstResourceGroupName='app-1-rg'
$firstDeploymentName='app-1-rg-dep'
$location1='East US' # First region to deploy into (see regional pairing for optimum selection)

# Create new resource group
New-AzureRmResourceGroup -Name $firstResourceGroupName -Location $location1

# Template and first parameter file URIs
$templateUri = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-vnet.json'
$templateParamUri1 = 'https://raw.githubusercontent.com/mspnp/blueprints/kirpas/multidc-arm-templates/multidc-windows/ArmTemplates/configure-vnet.v1.param.json'

Test-AzureRmResourceGroupDeployment -ResourceGroupName $firstResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri1
New-AzureRmResourceGroupDeployment -Name $firstDeploymentName -ResourceGroupName $firstResourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri1 -Verbose

#############################################################################
# Deploy infrastructure in second region