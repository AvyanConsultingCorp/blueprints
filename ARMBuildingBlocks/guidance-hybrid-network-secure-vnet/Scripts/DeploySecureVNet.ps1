#
# DeploySecureVNet.ps1
#
Login-AzureRmAccount

$location       = "centralus"
$templatesPath  = "https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/guidance-hybrid-network-secure-vnet/Templates/"

$templateOnPrem = "azuredeploy-onprem.json"
$onpremParametersObject = @{ `
                        baseName="op"; `
                        vnetAddressPrefix="192.168.0.0/16"; `
                        subnetNamePrefix="subnet1"; `
                        subnetPrefix="192.168.1.0/24"; `
                        gatewaySubnetPrefix="192.168.224.0/27"; `
                        osType = "Ubuntu"; `
                        vmNamePrefix = "web"; `
                        vmComputerName = "web1"; `
                        adminUsername = "adminUser"; `
                        }
$onpremRG = $onpremParametersObject["baseName"] + "-rg"

New-AzureRmResourceGroup -Name $onpremRG -Location $location

$onpremDeploy = New-AzureRmResourceGroupDeployment -ResourceGroupName $onpremRG `
    -TemplateUri $templatesPath$templateOnPrem `
    -TemplateParameterObject $onpremParametersObject

$templateAzure  = "azuredeploy-workload.json"