Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId '6df485a0-aafa-4020-893d-32e833d056d6'

#############################################################################
# Make sure that the following parameters match the ones in the template

$resourceGroupName='app0-rg'
$deploymentName='app0-rg-dep'
$location='West US'

$vnetName='app0-vnet'
$subnetIn='app0-in-subnet'
$subnetOut='app0-out-subnet'
$avsetName='app0-web-as'

$vnetAddressPrefix='10.0.0.0/16'
$subnetInPrefix='10.0.1.0/24'
$subnetOutPrefix='10.0.2.0/24'

$gatewaySubnetNamePrefix='10.0.255.224/27'

$storageAccountVhd='app0devvmst'
$storageAccountDiag='app0devdiag'

$gatewaySubnetName='GatewaySubnet'

# Create new resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Set subnet config
$subNet1=New-AzureRmVirtualNetworkSubnetConfig -Name $subnetIn -AddressPrefix $subnetInPrefix
$subNet2=New-AzureRmVirtualNetworkSubnetConfig -Name $subnetOut -AddressPrefix $subnetOutPrefix
$subNet3=New-AzureRmVirtualNetworkSubnetConfig -Name $gatewaySubnetName -AddressPrefix $gatewaySubnetNamePrefix

# Create a new VNet
New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -AddressPrefix $vnetAddressPrefix  -Location $location -Subnet $subNet1, $subNet2, $subnet3

# Create VPN gateway with a public IP
$gwpip= New-AzureRmPublicIpAddress -Name gwpip -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $gatewaySubnetName -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id
New-AzureRmVirtualNetworkGateway -Name vnetgw1 -ResourceGroupName $resourceGroupName -Location $location -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard

# Template and first parameter file URIs
$templateUri = 'https://raw.githubusercontent.com/mspnp/blueprints/refarch/buildingblocks/ARMBuildingBlocks/ARMBuildingBlocks/Templates/buildingBlocks/nvas-ntier-network/azuredeploy.json'
$templateParamUri = 'https://raw.githubusercontent.com/mspnp/blueprints/refarch/buildingblocks/ARMBuildingBlocks/ARMBuildingBlocks/Templates/buildingBlocks/nvas-ntier-network/scenarios/2-nva-gwy-vm-ipfwding-enabled.parameters.json'

$result = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri
if($result.Count -eq 0){
	New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParamUri -Verbose
}else{
    $result
}
