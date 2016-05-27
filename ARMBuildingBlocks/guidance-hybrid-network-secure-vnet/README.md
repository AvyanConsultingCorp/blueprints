# Implementing a secure hybrid network architecture in Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2Fguidance-hybrid-network-secure-vnet%2FTemplates%2Fra-vnet-subnets-udr-nsg%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fblueprints%2Fmaster%2FARMBuildingBlocks%2Fguidance-hybrid-network-secure-vnet%2FTemplates%2Fra-vnet-subnets-udr-nsg%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

<p>This template is used to deploy the architecture reference described in [Implementing a secure hybrid network architecture in Azure](https://azure.microsoft.com/en-us/documentation/articles/guidance-iaas-ra-secure-vnet-hybrid/), which describes best practices for implementing a secure hybrid network that extends your on-premises network to Azure. In this reference architecture, you will learn how to use user defined routes (UDRs) to route incoming traffic on a virtual network through a set of highly available network virtual appliances. These appliances can run different types of security software, such as firewalls, packet inspection, among others. You will also learn how to enable forced tunneling, to route all outgoing traffic from the VNet to the Internet through your on-premises data center so that it can be audited. </p>

<p>This template also uses several [building block templates](https://github.com/mspnp/blueprints/tree/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates), that you can reuse for your own deployments.</p>
