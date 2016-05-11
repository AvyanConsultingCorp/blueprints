
# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

############################################################################

if [ $# -ne 5 ] 
then
    echo "Usage: ${0} appname subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix"
    echo "For example: ${0} mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24"
    exit
fi

############################################################################
## Command Arguments
############################################################################
BASE_NAME=$1
SUBSCRIPTION=$2
VPN_IPSEC_SHARED_KEY=$3
ON_PREMISES_PUBLIC_IP=$4
ON_PREMISES_ADDRESS_SPACE=$5

LOCATION=centralus
azure config mode arm

# create network 
TEMPLATE_URI=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-vnet-6subnets.json
RESOURCE_GROUP=${BASE_NAME}-ntwk-rg
ON_PREM_NET_PREFIX=${ON_PREMISES_ADDRESS_SPACE}
VNET_PREFIX=10.0.0.0/16
VNET_MANAGE_SUBNET_PREFIX=10.0.0.0/24
VNET_NVA_FE_SUBNET_PREFIX=10.0.1.0/24
VNET_NVA_BE_SUBNET_PREFIX=10.0.2.0/24
VNET_WEB_SUBNET_PREFIX=10.0.3.0/24
VNET_BIZ_SUBNET_PREFIX=10.0.4.0/24
VNET_DB_SUBNET_PREFIX=10.0.5.0/24
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"onpremNetPrefix\":{\"value\":\"${ON_PREM_NET_PREFIX}\"},\"vnetPrefix\":{\"value\":\"${VNET_PREFIX}\"},\"vnetManageSubnetPrefix\":{\"value\":\"${VNET_MANAGE_SUBNET_PREFIX}\"},\"vnetNvaFeSubnetPrefix\":{\"value\":\"${VNET_NVA_FE_SUBNET_PREFIX}\"},\"vnetNvaBeSubnetPrefix\":{\"value\":\"${VNET_NVA_BE_SUBNET_PREFIX}\"},\"vnetWebSubnetPrefix\":{\"value\":\"${VNET_WEB_SUBNET_PREFIX}\"},\"vnetBizSubnetPrefix\":{\"value\":\"${VNET_BIZ_SUBNET_PREFIX}\"},\"vnetDbSubnetPrefix\":{\"value\":\"${VNET_DB_SUBNET_PREFIX}\"}}"
azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# the following variables are used in the above resource group, you need to use them later to create web/biz/db tier. don't change their values.
NTWK_RESOURCE_GROUP=${RESOURCE_GROUP}
WEB_SUBNET_NAME_PREFIX=web
BIZ_SUBNET_NAME_PREFIX=biz
DB_SUBNET_NAME_PREFIX=db

# create ilb and vm in web/biz/db tier
TEMPLATE_URI=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json

WEB_ILB_IP_ADDRESS=10.0.3.254
BIZ_ILB_IP_ADDRESS=10.0.4.254
DB_ILB_IP_ADDRESS=10.0.5.254

# use the following same parameters for web, biz, and db tiere. you can change them for each tier.
ADMIN_USER_NAME=adminUser
ADMIN_PASSWORD=adminP@ssw0rd
OS_TYPE=Windows

# create web tier
SUBNET_NAME_PREFIX=${WEB_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${WEB_ILB_IP_ADDRESS}
NUMBER_VMS=2

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME=${SUBNET_NAME_PREFIX}
SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"subnetId\":{\"value\":\"${SUBNET_ID}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerName\":{\"value\":\"${VM_COMPUTER_NAME}\"}}"
azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# create biz tier
SUBNET_NAME_PREFIX=${BIZ_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${BIZ_ILB_IP_ADDRESS}
NUMBER_VMS=2

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME=${SUBNET_NAME_PREFIX}
SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"subnetId\":{\"value\":\"${SUBNET_ID}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerName\":{\"value\":\"${VM_COMPUTER_NAME}\"}}"
azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# create db tier
SUBNET_NAME_PREFIX=${DB_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${DB_ILB_IP_ADDRESS}
NUMBER_VMS=2

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME=${SUBNET_NAME_PREFIX}
SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${SUBNET_NAME_PREFIX}-subnet
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"subnetId\":{\"value\":\"${SUBNET_ID}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerName\":{\"value\":\"${VM_COMPUTER_NAME}\"}}"
azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

