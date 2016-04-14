::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Modify data about your hub-and-spoke topology here. 
:: Only modify the values, do not modify the variable names.
::
SET ENVIRONMENT=dev

:: hub vnet data
SET HUB_CIDR=10.0.0.0/16
SET HUB_INTERNAL_CIDR=10.0.0.0/24
SET HUB_GATEWAY_CIDR=10.0.255.224/27
SET HUB_LOCATION=eastus
::
:: spoke vnet SP1 data
SET SP1_CIDR=10.1.0.0/16
SET SP1_INTERNAL_CIDR=10.1.0.0/24
SET SP1_GATEWAY_CIDR=10.1.255.224/27
SET SP1_ILB=10.1.0.254
SET SP1_LOCATION=eastus
::
:: spoke vnet SP2 data
SET SP2_CIDR=10.2.0.0/16
SET SP2_INTERNAL_CIDR=10.2.0.0/24
SET SP2_GATEWAY_CIDR=10.2.255.224/27
SET SP2_ILB=10.2.0.254
SET SP2_LOCATION=eastus
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Global variables
::
:: hub vnet variables
SET HUB_NAME=%RESOURCE_PREFIX%-hub
SET HUB_GATEWAY_NAME=%HUB_NAME%-vgw
SET HUB_GATEWAY_PIP_NAME=%HUB_NAME%-pip
SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg
::
:: on-prem network ONP variables
SET ONP_NAME=%RESOURCE_PREFIX%-onp
SET ONP_GATEWAY_NAME=%ONP_NAME%-vgw
SET ONP_LOCATION=%HUB_LOCATION%
SET ONP_RESOURCE_GROUP=%HUB_RESOURCE_GROUP%
::
:: spoke vnet SP1 variables
SET SP1_NAME=%RESOURCE_PREFIX%-sp1
SET SP1_GATEWAY_NAME=%SP1_NAME%-vgw
SET SP1_GATEWAY_PIP_NAME=%SP1_NAME%-pip
SET SP1_RESOURCE_GROUP=%SP1_NAME%-%ENVIRONMENT%-rg
::
:: spoke vnet SP2 variables
SET SP2_NAME=%RESOURCE_PREFIX%-sp2
SET SP2_GATEWAY_NAME=%SP2_NAME%-vgw
SET SP2_GATEWAY_PIP_NAME=%SP2_NAME%-pip
SET SP2_RESOURCE_GROUP=%SP2_NAME%-%ENVIRONMENT%-rg
::
:: gateway address space CIDR list
:: You need enclose the CIDR list in quotes because they are comma seperated, 
:: If without the quotes, the script subroutine will treat each CIDR as a seperate variable.
::
SET ONP_TO_HUB_CIDR_LIST="%HUB_CIDR%,%SP1_CIDR%,%SP2_CIDR%"
SET SP1_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP2_CIDR%"
SET SP2_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
