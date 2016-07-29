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
DOMAIN_NAME=
ADMIN_USER_NAME=
ADMIN_PASSWORD=
ON_PREMISES_PUBLIC_IP=
ON_PREMISES_ADDRESS_SPACE=
VPN_IPSEC_SHARED_KEY=
ON_PREMISES_DNS_SERVER_ADDRESS=
ON_PREMISES_DNS_SUBNET_PREFIX=
############################################################################

############################################################################
## Other configuation data
############################################################################

# step-by-step prompt for this script, set it to true will allow you 
# to check and verify each step before going to the next step. 
Prompting=true-not

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
# Set azure CLI to arm mode
############################################################################

echo
echo
echo azure config mode arm
     azure config mode arm

############################################################################

DEPLOYED_VNET_NAME=${BASE_NAME}-vnet
DEPLOYED_ADFS_SUBNET_NAME_PREFIX=adfs
DEPLOYED_ADFS_SUBNET_NAME=${BASE_NAME}-adfs-sn
NTWK_RESOURCE_GROUP=${BASE_NAME}-ntwk-rg

ADFS_RESOURCE_GROUP=${BASE_NAME}-adfs-rg
RESOURCE_GROUP=${ADFS_RESOURCE_GROUP}

############################################################################
# Install ADFS Farm in the first VM 
############################################################################
############################################################################
if [ "${Prompting}" == "true" ]; then
	echo
	echo
	read -p "Press any key to install ADFS to the first VM ... " -n1 -s
fi

do
	VM_NAME=${BASE_NAME}-${VM_NAME_PREFIX}1-vm
	TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-vm-joindomain-extension.json
	PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"},\"domainName\":{\"value\":\"${DOMAIN_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"}}"
	echo
	echo
	echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
	     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
done  


if [ "${Prompting}" == "true" ]; then
	echo
	echo
	echo -n "Please go to the on-premises AD server to verify that the computers have been added to the domain"
	echo
	echo
	read -p "Press any key to continue ... " -n1 -s
fi
	 
############################################################################
# Install ADFS in the second and the rest VMs 
############################################################################


