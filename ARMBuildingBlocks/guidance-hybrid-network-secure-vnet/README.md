# Implementing a secure hybrid network architecture in Azure

This template is used to deploy part of the architecture reference described in [Implementing a secure hybrid network architecture in Azure](https://azure.microsoft.com/en-us/documentation/articles/guidance-iaas-ra-secure-vnet-hybrid/), which describes best practices for implementing a secure hybrid network that extends your on-premises network to Azure. In this reference architecture, you will learn how to use user defined routes (UDRs) to route incoming traffic on a virtual network through a set of highly available network virtual appliances. These appliances can run different types of security software, such as firewalls, packet inspection, among others. You will also learn how to enable forced tunneling, to route all outgoing traffic from the VNet to the Internet through your on-premises data center so that it can be audited.

This template also uses several [building block templates](https://github.com/mspnp/blueprints/tree/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates), that you can reuse for your own deployments.

## Architecture diagram

The following diagram highlights the important components in this architecture (click to zoom in):

[![0]][0]

The architecture shown above is deployed by using different resource groups, as shown below.

[![1]][1]

The table below shows all templates used to deploy the entire architecture, and show in the picture above:

## Deployment

To deploy each resource group, use the templates below. We recommend you read through the [deployment documentation](https://azure.microsoft.com/en-us/documentation/articles/guidance-iaas-ra-secure-vnet-hybrid/#deploying-the-sample-solution) before using the links below.

<table>
<tr>
<td><b>Resource group</b></td>
<td><b>Deploy</b></td>
<td><b>Visualize</b></td>
</tr>
<tr>
<td>myapp-netwk-rg</td>
<td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2Fguidance-hybrid-network-secure-vnet%2FTemplates%2Fra-vnet-subnets-udr-nsg%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</td>
<td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2Fguidance-hybrid-network-secure-vnet%2FTemplates%2Fra-vnet-subnets-udr-nsg%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
</td>
</tr>
<tr>
<td>myapp-web-subnet-rg</td>
<td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</td>
<td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
</td>
</tr>
<tr>
<td>myapp-biz-subnet-rg</td>
<td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</td>
<td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
</td>
</tr>
<tr>
<td>myapp-data-subnet-rg</td>
<td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</td>
<td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fbb-ilb-backend-http-https.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
</td>
</tr>
<tr>
<td>myapp-mgmt-subnet-rg</td>
<td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fibb-nvas-mgmt.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</td>
<td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2FARMBuildingBlocks%2FTemplates%2Fibb-nvas-mgmt.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
</td>
</tr>
</table>

[0]: https://acom.azurecomcdn.net/80C57D/cdn/mediahandler/docarticles/dpsmedia-prod/azure.microsoft.com/en-us/documentation/articles/guidance-iaas-ra-secure-vnet-hybrid/20160526050049/figure1.png "Secure hybrid network architecture"
[1]: https://acom.azurecomcdn.net/80C57D/cdn/mediahandler/docarticles/dpsmedia-prod/azure.microsoft.com/en-us/documentation/articles/guidance-iaas-ra-secure-vnet-hybrid/20160527062741/resource-groups.gif "Resource group progression"