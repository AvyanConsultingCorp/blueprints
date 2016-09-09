############################################################################
############################################################################
############################################################################
############################################################################
##  Configurations
############################################################################

############################################################################
## You must fill in the following configuration data
############################################################################
BASE_NAME=
SUBSCRIPTION=
LOCATION=
OS_TYPE=
ADMIN_USER_NAME=
ADMIN_PASSWORD=

DOMAIN_NAME=
NET_BIOS_DOMAIN_NAME=
ON_PREMISES_PUBLIC_IP=
ON_PREMISES_ADDRESS_SPACE=
VPN_IPSEC_SHARED_KEY=
ON_PREMISES_DNS_SERVER_ADDRESS=
ON_PREMISES_DNS_SUBNET_PREFIX=
############################################################################
ADFS_GMSA_NAME=adfsgmsa
ADFS_HOST_NAME=adfs
ADFS_FEDERATION_NAME=${ADFS_HOST_NAME}.${DOMAIN_NAME}

############################################################################
## Other configuation data
############################################################################

# step-by-step prompt for this script, set it to true will allow you 
# to check and verify each step before going to the next step. 
Prompting=true

# location of arm templates
URI_BASE=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks

############################################################################
# Active directory site name in on-premises network
ONPREM_SITE_NAME=Default-First-Site-Name
# Active directory replication site name in azure vNet
SITE_NAME=Azure-Vnet-Ad-Site
# Active directry site replication frequency in minutes
REPLICATION_FREQUENCY=15

############################################################################
# DSC type handler version
DSC_TYPE_HANDLER_VERSION=2.19

############################################################################
# vNet and subnet address prefix

VNET_PREFIX=10.0.0.0/16

VNET_NVA_FE_SUBNET_PREFIX=10.0.0.0/27
VNET_NVA_BE_SUBNET_PREFIX=10.0.0.32/27
VNET_DMZ_FE_SUBNET_PREFIX=10.0.0.64/27
VNET_DMZ_BE_SUBNET_PREFIX=10.0.0.96/27
VNET_MGMT_SUBNET_PREFIX=10.0.0.128/25

VNET_WEB_SUBNET_PREFIX=10.0.1.0/24
VNET_BIZ_SUBNET_PREFIX=10.0.2.0/24
VNET_DB_SUBNET_PREFIX=10.0.3.0/24

VNET_GATEWAY_SUBNET_ADDRESS_PREFIX=10.0.255.224/27
VNET_AD_SUBNET_PREFIX=10.0.255.192/27
VNET_ADFS_SUBNET_PREFIX=10.0.255.160/27
VNET_ADFS_PROXY_SUBNET_PREFIX=10.0.255.128/27

############################################################################
# static private address for ILBs and Servers
AD_SERVER_IP_ADDRESSES=\"10.0.255.222\",\"10.0.255.221\"
AD_SERVER_IP_ADDRESS_ARRAY=[${AD_SERVER_IP_ADDRESSES}]
DNS_SERVER_ADDRESS_ARRAY=[${AD_SERVER_IP_ADDRESSES},\"${ON_PREMISES_DNS_SERVER_ADDRESS}\"]

ADFS_ILB_IP_ADDRESS=10.0.255.190
ADFS_SERVER_IP_ADDRESS_ARRAY=[\"10.0.255.189\",\"10.0.255.188\"]

ADFS_PROXY_ILB_IP_ADDRESS=10.0.255.158
ADFS_PROXY_SERVER_IP_ADDRESS_ARRAY=[\"10.0.255.157\",\"10.0.255.156\"]

MGMT_JUMPBOX_IP_ADDRESS=10.0.0.254
NVA_MGMT_VM_IP_ADDRESSES=[\"10.0.0.253\",\"10.0.0.252\"]
DMZ_MGMT_VM_IP_ADDRESSES=[\"10.0.0.251\",\"10.0.0.250\"]

DMZ_BE_VM_IP_ADDRESSES=[\"10.0.0.126\",\"10.0.0.125\"]
DMZ_FE_VM_IP_ADDRESSES=[\"10.0.0.94\",\"10.0.0.93\"]

NVA_BE_VM_IP_ADDRESSES=[\"10.0.0.62\",\"10.0.0.61\"]

NVA_FE_ILB_IP_ADDRESS=10.0.0.30
NVA_FE_VM_IP_ADDRESSES=[\"10.0.0.29\",\"10.0.0.28\"]

WEB_ILB_IP_ADDRESS=10.0.1.254

BIZ_ILB_IP_ADDRESS=10.0.2.254

DB_ILB_IP_ADDRESS=10.0.3.254

############################################################################
# Number of VMs in each tier
WEB_NUMBER_VMS=2
BIZ_NUMBER_VMS=2
DB_NUMBER_VMS=2
AD_NUMBER_VMS=2
ADFS_NUMBER_VMS=2
ADFS_PROXY_NUMBER_VMS=2

############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
# Error Handling
############################################################################

############################################################################
# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

function validate() {
    for i in "${@:2}"; do
      if [[ "$1" == "$i" ]]
      then
        return 1
      fi
    done
    
    return 0
}

function validateNotEmpty() {
    if [[ "$1" != "" ]]
    then
      return 1
    else
      return 0
    fi
}

if validateNotEmpty ${SUBSCRIPTION};
then
  echo "A value for SUBSCRIPTION must be provided"
  exit
fi

if validateNotEmpty ${BASE_NAME};
then
  echo "A value for BASE_NAME must be provided"
  exit
fi
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################

############################################################################
# Set azure CLI to arm mode
############################################################################

echo
echo
echo azure config mode arm
     azure config mode arm
	 
############################################################################
############################################################################
############################################################################
############################################################################
## Create vNet (my-ntwk-rg)
############################################################################

TEMPLATE_URI=${URI_BASE}/guidance-iaas-ra-aad/Templates/ra-aad/azuredeploy.json
NTWK_RESOURCE_GROUP=${BASE_NAME}-ntwk-rg
RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
ON_PREM_NET_PREFIX=${ON_PREMISES_ADDRESS_SPACE}
DNS_SERVERS=[]
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"dnsServers\":{\"value\":${DNS_SERVERS}},\"onpremNetPrefix\":{\"value\":\"${ON_PREM_NET_PREFIX}\"},\"onpremDnsSubnetPrefix\":{\"value\":\"${ON_PREMISES_DNS_SUBNET_PREFIX}\"},\"vnetPrefix\":{\"value\":\"${VNET_PREFIX}\"},\"vnetAdSubnetPrefix\":{\"value\":\"${VNET_AD_SUBNET_PREFIX}\"},\"vnetAdfsSubnetPrefix\":{\"value\":\"${VNET_ADFS_SUBNET_PREFIX}\"},\"vnetAdfsProxySubnetPrefix\":{\"value\":\"${VNET_ADFS_PROXY_SUBNET_PREFIX}\"},\"vnetMgmtSubnetPrefix\":{\"value\":\"${VNET_MGMT_SUBNET_PREFIX}\"},\"vnetNvaFeSubnetPrefix\":{\"value\":\"${VNET_NVA_FE_SUBNET_PREFIX}\"},\"vnetNvaBeSubnetPrefix\":{\"value\":\"${VNET_NVA_BE_SUBNET_PREFIX}\"},\"vnetWebSubnetPrefix\":{\"value\":\"${VNET_WEB_SUBNET_PREFIX}\"},\"vnetBizSubnetPrefix\":{\"value\":\"${VNET_BIZ_SUBNET_PREFIX}\"},\"vnetDbSubnetPrefix\":{\"value\":\"${VNET_DB_SUBNET_PREFIX}\"},\"vnetGwSubnetPrefix\":{\"value\":\"${VNET_GATEWAY_SUBNET_ADDRESS_PREFIX}\"},\"vnetDmzFeSubnetPrefix\":{\"value\":\"${VNET_DMZ_FE_SUBNET_PREFIX}\"},\"vnetDmzBeSubnetPrefix\":{\"value\":\"${VNET_DMZ_BE_SUBNET_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
	 
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}

# the following variables are used in the above resource group, you need to use them later to create web/biz/db tier. don't change their values.
DEPLOYED_VNET_NAME=${BASE_NAME}-vnet

DEPLOYED_AD_SUBNET_NAME_PREFIX=ad

DEPLOYED_ADFS_SUBNET_NAME_PREFIX=adfs
DEPLOYED_ADFS_SUBNET_NAME=${BASE_NAME}-adfs-sn

DEPLOYED_ADFS_PROXY_SUBNET_NAME_PREFIX=adfs-proxy
DEPLOYED_ADFS_PROXY_SUBNET_NAME=${BASE_NAME}-adfs-proxy-sn

DEPLOYED_MGMT_SUBNET_NAME_PREFIX=mgmt
DEPLOYED_NVA_FE_SUBNET_NAME_PREFIX=nva-fe
DEPLOYED_NVA_BE_SUBNET_NAME_PREFIX=nva-be
DEPLOYED_WEB_SUBNET_NAME_PREFIX=web
DEPLOYED_BIZ_SUBNET_NAME_PREFIX=biz
DEPLOYED_DB_SUBNET_NAME_PREFIX=db

DEPLOYED_WEB_SUBNET_NAME=${BASE_NAME}-web-sn
DEPLOYED_BIZ_SUBNET_NAME=${BASE_NAME}-biz-sn
DEPLOYED_DB_SUBNET_NAME=${BASE_NAME}-db-sn

DEPLOYED_WEB_UDR_NAME=${BASE_NAME}-web-udr
DEPLOYED_BIZ_UDR_NAME=${BASE_NAME}-biz-udr
DEPLOYED_DB_UDR_NAME=${BASE_NAME}-db-udr

DEPLOYED_DMZ_FE_SUBNET_NAME_PREFIX=dmz-fe
DEPLOYED_DMZ_BE_SUBNET_NAME_PREFIX=dmz-be

if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please verify that the VNet has been created "
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi
############################################################################
############################################################################
############################################################################
############################################################################
## Create Web Tiere (my-web-tier-rg)
############################################################################

############################################################################
# create web tier (ILB and VMs)
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
SUBNET_NAME_PREFIX=${DEPLOYED_WEB_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${WEB_ILB_IP_ADDRESS}
NUMBER_VMS=${WEB_NUMBER_VMS}

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-tier-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VNET_RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
VNET_NAME=${DEPLOYED_VNET_NAME}
SUBNET_NAME=${DEPLOYED_WEB_SUBNET_NAME}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetResourceGroup\":{\"value\":\"${VNET_RESOURCE_GROUP}\"},\"vnetName\":{\"value\":\"${VNET_NAME}\"},\"subnetName\":{\"value\":\"${SUBNET_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerNamePrefix\":{\"value\":\"${VM_COMPUTER_NAME_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}

############################################################################
# install iis/apache to web vms
for (( i=1; i<=${NUMBER_VMS}; i++ ))
do
	VM_NAME=${BASE_NAME}-${VM_NAME_PREFIX}${i}-vm
	if [ "${OS_TYPE}" == "Windows" ]; then
		TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-vm-iis.json
		PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"},\"dscTypeHandlerVersion\":{\"value\":\"${DSC_TYPE_HANDLER_VERSION}\"}}"
		
		echo
		echo
		echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
		     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
	fi
	if [ "${OS_TYPE}" == "Ubuntu" ]; then
		TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-vm-apache.json
		PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"}}"
		echo
		echo
		echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
		     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
	fi
done  

if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please verify that the Web tier has been created correctly"
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi
 
############################################################################
############################################################################
############################################################################
############################################################################
## Create Management Resources (my-mgmt-rg)
############################################################################

############################################################################
## Create ILB and NVA VMs in nva subnet
############################################################################
MGMT_RESOURCE_GROUP=${BASE_NAME}-mgmt-rg
RESOURCE_GROUP=${MGMT_RESOURCE_GROUP}
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-nvas.json

MGMT_SUBNET_NAME_PREFIX=${DEPLOYED_MGMT_SUBNET_NAME_PREFIX}
NVA_FE_SUBNET_NAME_PREFIX=${DEPLOYED_NVA_FE_SUBNET_NAME_PREFIX}
NVA_BE_SUBNET_NAME_PREFIX=${DEPLOYED_NVA_BE_SUBNET_NAME_PREFIX}

MGMT_SUBNET_PREFIX=${VNET_MGMT_SUBNET_PREFIX}
VNET_PREFIX=${VNET_PREFIX}

FE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${NVA_FE_SUBNET_NAME_PREFIX}-sn
BE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${NVA_BE_SUBNET_NAME_PREFIX}-sn
MGMT_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${MGMT_SUBNET_NAME_PREFIX}-sn
ILB_IP_ADDRESS=${NVA_FE_ILB_IP_ADDRESS}
VM_SIZE=Standard_DS3

VM_IP_ADDRESS_1_ARRAY=${NVA_FE_VM_IP_ADDRESSES}
VM_IP_ADDRESS_2_ARRAY=${NVA_BE_VM_IP_ADDRESSES}
VM_IP_ADDRESS_3_ARRAY=${NVA_MGMT_VM_IP_ADDRESSES}

PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vmIPaddress1Array\":{\"value\":${VM_IP_ADDRESS_1_ARRAY}},\"vmIPaddress2Array\":{\"value\":${VM_IP_ADDRESS_2_ARRAY}},\"vmIPaddress3Array\":{\"value\":${VM_IP_ADDRESS_3_ARRAY}},\"vnetPrefix\":{\"value\":\"${VNET_PREFIX}\"},\"mgmtSubnetPrefix\":{\"value\":\"${MGMT_SUBNET_PREFIX}\"},\"feSubnetId\":{\"value\":\"${FE_SUBNET_ID}\"},\"beSubnetId\":{\"value\":\"${BE_SUBNET_ID}\"},\"mgmtSubnetId\":{\"value\":\"${MGMT_SUBNET_ID}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"vmSize\":{\"value\":\"${VM_SIZE}\"}}"
echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}

# The following parameters are from the mgmt tier, and is needed for vpn creation
DEPLOYED_GW_UDR_NAME=${BASE_NAME}-gw-udr

if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please verify that the NVA has been created correctly"
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi

############################################################################
## Create jumbox in management subnet
############################################################################
MGMT_RESOURCE_GROUP=${BASE_NAME}-mgmt-rg
RESOURCE_GROUP=${MGMT_RESOURCE_GROUP}
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-mgmt-jumpbox.json

MGMT_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${MGMT_SUBNET_NAME_PREFIX}-sn
JUMPBOX_IP_ADDRESS=${MGMT_JUMPBOX_IP_ADDRESS}
JUMPBOX_OS_TYPE=${OS_TYPE}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"mgmtSubnetId\":{\"value\":\"${MGMT_SUBNET_ID}\"},\"jumpboxIpAddress\":{\"value\":\"${JUMPBOX_IP_ADDRESS}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"jumpboxOSType\":{\"value\":\"${JUMPBOX_OS_TYPE}\"}}"
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}

if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please verify that the jumpbox has been created correctly"
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi

############################################################################
############################################################################
############################################################################
############################################################################
## Create DMZ (my-dmz-rg)
############################################################################

############################################################################
## Create my-dmz-rg resource group
############################################################################
DMZ_RESOURCE_GROUP=${BASE_NAME}-dmz-rg
RESOURCE_GROUP=${DMZ_RESOURCE_GROUP}
echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}

############################################################################
## Create Public LB and NVA Vms in dmz subnet 
############################################################################
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-dmz-2pip.json
DMZ_FE_SUBNET_NAME_PREFIX=${DEPLOYED_DMZ_FE_SUBNET_NAME_PREFIX}
DMZ_BE_SUBNET_NAME_PREFIX=${DEPLOYED_DMZ_BE_SUBNET_NAME_PREFIX}
FE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${DMZ_FE_SUBNET_NAME_PREFIX}-sn
BE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${DMZ_BE_SUBNET_NAME_PREFIX}-sn
VM_SIZE=Standard_DS3
PUBLIC_IP_ADDRESS1_NAME=${BASE_NAME}-dmz-pip1
PUBLIC_IP_ADDRESS2_NAME=${BASE_NAME}-dmz-pip2

VM_IP_ADDRESS_1_ARRAY=${DMZ_FE_VM_IP_ADDRESSES}
VM_IP_ADDRESS_2_ARRAY=${DMZ_BE_VM_IP_ADDRESSES}
VM_IP_ADDRESS_3_ARRAY=${DMZ_MGMT_VM_IP_ADDRESSES}

PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vmIPaddress1Array\":{\"value\":${VM_IP_ADDRESS_1_ARRAY}},\"vmIPaddress2Array\":{\"value\":${VM_IP_ADDRESS_2_ARRAY}},\"vmIPaddress3Array\":{\"value\":${VM_IP_ADDRESS_3_ARRAY}},\"feSubnetId\":{\"value\":\"${FE_SUBNET_ID}\"},\"beSubnetId\":{\"value\":\"${BE_SUBNET_ID}\"},\"mgmtSubnetId\":{\"value\":\"${MGMT_SUBNET_ID}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"vmSize\":{\"value\":\"${VM_SIZE}\"},\"publicIPAddress1Name\":{\"value\":\"${PUBLIC_IP_ADDRESS1_NAME}\"},\"publicIPAddress2Name\":{\"value\":\"${PUBLIC_IP_ADDRESS2_NAME}\"}}"
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
	 
if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please verify that the DMZ has been created correctly"
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi
