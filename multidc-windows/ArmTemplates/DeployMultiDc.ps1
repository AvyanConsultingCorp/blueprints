Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName 'Pnp Azure'

$firstResourceGroupName='multidc-1-rg'
$firstDeploymentName='multidc-1-rg-dep'

$secondResourceGroupName='multidc-2-rg'
$secondDeploymentName='multidc-2-rg-dep'

# Change the location accordingly - supported values may be obtained using REST call below:
# https://management.core.windows.net/<subscription-id>/locations
$location1='West US' 
$location2='East US'

# Omit the below step if you are using an existing resource group
New-AzureRmResourceGroup -Name $firstResourceGroupName -Location $location1
New-AzureRmResourceGroup -Name $secondResourceGroupName -Location $location2


$templatePath = .\ConfigureVnet.json
$templateParamPath = .\ConfigureVnet.param.dev.json

Test-AzureRmResourceGroupDeployment -ResourceGroupName $firstResourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose
New-AzureRmResourceGroupDeployment -Name $firstDeploymentName -ResourceGroupName $firstResourceGroupName  -TemplateFile $templatePath -TemplateParameterFile $templateParamPath -Verbose

#Get-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName

#Get-AzureRmResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
