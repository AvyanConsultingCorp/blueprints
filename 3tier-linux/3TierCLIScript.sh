#!/bin/bash
############################################################################
#script for generating infrastructure for 3 tier plus linux VMS of         #
# user choice. It creates azure resource group, storage accounts for VMS   #
# vnet, subnets for tiers, load balancer if required and NSG rules         #
# tags for main variables used                                             #
# ScriptCommandParameters                                                  #
# ScriptVars                                                               #
############################################################################

############################################################################
# User defined functions for 3tier script                                  #
# errhandle : handles errors via trap if any exception happens             # 
# in the cli execution or if the user interrupts with CTRL+C               #
# allowing for fast interruption                                           #
# CreateVM: provisions the VMS for the tiers. Parameters: VM Name,Tier name#
# (web, biz, db, manage) avalability set(true or false) Load balancer name #
# CreateCommonLBResources:creates the probe and rules for the load balancer#
############################################################################

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{ 
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

CreateVm()
{
  echo "Creating VM ${1} in tier ${2} availability set ${3} lb (empty if none) ${4} "

  TIER_NAME=$2
  SUBNET_NAME=$3
  NEEDS_AVAILABILITY_SET=$4
  LB_NAME=$5
  AVAILSET_NAME="${APP_NAME}-${TIER_NAME}-as"
  VM_NAME="${APP_NAME}-${TIER_NAME}-vm${1}"
  NIC_NAME="${VM_NAME}-nic1"
  VHD_STORAGE="${VM_NAME//-}st1"

  # Create NIC for VM
  azure network nic create --name $NIC_NAME --subnet-name $SUBNET_NAME \
  --subnet-vnet-name $VNET_NAME --location $LOCATION $POSTFIX

  if [ ! -z $LB_NAME ]
  then

     # Add NIC to back-end address pool
     LB_BACKEND_NAME="${LB_NAME}-backend-pool"
     azure network nic address-pool create --name $NIC_NAME --lb-name $LB_NAME \
	  --lb-address-pool-name $LB_BACKEND_NAME $POSTFIX
  fi

  # Create the storage account for the OS VHD
  azure storage account create --type PLRS --location $LOCATION \
    $VHD_STORAGE $POSTFIX

  # Create the VM

  if [ $NEEDS_AVAILABILITY_SET = true ]
  then
      azure vm create --name $VM_NAME --os-type Linux --image-urn \
	$LINUX_BASE_IMAGE --vm-size $VM_SIZE --vnet-subnet-name $SUBNET_NAME \
	--nic-name $NIC_NAME --vnet-name $VNET_NAME --storage-account-name \
	$VHD_STORAGE --os-disk-vhd "${VM_NAME}-osdisk.vhd" --admin-username \
	$USERNAME --ssh-publickey-file $PUBLICKEYFILE --boot-diagnostics-storage-uri \
        "https://${DIAGNOSTICS_STORAGE}.blob.core.windows.net/" --availset-name \
        $AVAILSET_NAME --location $LOCATION $POSTFIX
  else
      azure vm create --name $VM_NAME --os-type Linux --image-urn \
      $LINUX_BASE_IMAGE --vm-size $VM_SIZE --vnet-subnet-name $SUBNET_NAME \
      --nic-name $NIC_NAME --vnet-name $VNET_NAME --storage-account-name \
      $VHD_STORAGE --os-disk-vhd "${VM_NAME}-osdisk.vhd" --admin-username \
      $USERNAME --ssh-publickey-file $PUBLICKEYFILE --boot-diagnostics-storage-uri \
      "https://${DIAGNOSTICS_STORAGE}.blob.core.windows.net/" \
      --location $LOCATION $POSTFIX
  fi

  # Attach a data disk
  azure vm disk attach-new --vm-name $VM_NAME --size-in-gb 128 --vhd-name \
  "${VM_NAME}-data1.vhd" --storage-account-name $VHD_STORAGE $POSTFIX

}

CreateCommonLBResources()
{
  echo "Creating resoures for load balancer ${1}"

  LB_NAME=$1
  LB_FRONTEND_NAME="${LB_NAME}-frontend"
  LB_BACKEND_NAME="${LB_NAME}-backend-pool"
  LB_PROBE_NAME="${LB_NAME}-probe"
  # Create LB back-end address pool
  azure network lb address-pool create --name $LB_BACKEND_NAME --lb-name \
  $LB_NAME $POSTFIX
  # Create a health probe for an HTTP endpoint
  azure network lb probe create --name $LB_PROBE_NAME --lb-name $LB_NAME \
  --port 80 --interval 5 --count 2 --protocol http --path "/" $POSTFIX

  # Create a load balancer rule for HTTP
  azure network lb rule create --name "${LB_NAME}-rule-http" --protocol tcp \
  --lb-name $LB_NAME --frontend-port 80 --backend-port 80 --frontend-ip-name \
  $LB_FRONTEND_NAME --probe-name $LB_PROBE_NAME $POSTFIX

}

###############################################################################
############################## End of user defined functions ##################
###############################################################################

# 3 paramaters are expected
# public key file needs to be generates ssh-keygen

if [ $# -ne 3  ]
then
	echo  "Usage:  ${0}  subscription-id admin-address-whitelist-CIDR-format public-ssh-key-file"
	exit
fi

if [ ! -f $3  ]
then
	echo "Public Key file ${3} does not exist. please generate it"
	echo "ssh-keygen -t rsa -b 2048"
	exit
fi

# Explicitly set the subscription to avoid confusion as to which subscription
# is active/default
# ScriptCommandParameters
SUBSCRIPTION=$1
ADMIN_ADDRESS_PREFIX=$2
PUBLICKEYFILE=$3

# Set up variables to build out the naming conventions for deploying
# the cluster

# The APP_NAME variable must not exceed 4 characters in size.
# If it does the 15 character size limitation of the VM name may be exceeded.
# ScriptVars
APP_NAME=app1
LOCATION=centralus
ENVIRONMENT=dev
USERNAME=testuser
NUM_VM_INSTANCES_WEB_TIER=3
NUM_VM_INSTANCES_BIZ_TIER=3
NUM_VM_INSTANCES_DB_TIER=2
NUM_VM_INSTANCES_MANAGE_TIER=1

VNET_IP_RANGE=10.0.0.0/16
WEB_SUBNET_IP_RANGE=10.0.0.0/24
BIZ_SUBNET_IP_RANGE=10.0.1.0/24
DB_SUBNET_IP_RANGE=10.0.2.0/24
MANAGE_SUBNET_IP_RANGE=10.0.3.0/24

# Set IP address of Internal Load Balancer in the high end of subnet's IP range
# to keep separate from IP addresses assigned to VM's that start at the low end.

BIZ_ILB_IP=10.0.1.250

REMOTE_ACCESS_PORT=22

# For UBUNTU,OPENSUSE,RHEL,CENTOS use the following command to get the list of URNs:
# UBUNTU
# azure vm image list eastus2 canonical
# SUSE
# azure vm image list eastus2 suse
# READ HAT
# azure vm image list eastus2 redhat
# CENTOS
# azure vm image list eastus2 openlogic

LINUX_BASE_IMAGE=canonical:ubuntuserver:14.04.3-LTS:14.04.201601190

# For a list of VM sizes see: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/
# To see the VM sizes available in a region:
# azure vm sizes --location <<location>>
VM_SIZE=Standard_DS1

# Set up the names of things using recommended conventions

RESOURCE_GROUP="${APP_NAME}-${ENVIRONMENT}-rg"
VNET_NAME="${APP_NAME}-vnet"
PUBLIC_IP_NAME="${APP_NAME}-pip"
DIAGNOSTICS_STORAGE="${APP_NAME//-}diag"
JUMPBOX_PUBLIC_IP_NAME="${APP_NAME}-jumpbox-pip"
JUMPBOX_NIC_NAME="${APP_NAME}-manage-vm1-nic1"

#Set up the postfix variables attached to most CLI commands
POSTFIX="--resource-group ${RESOURCE_GROUP} --subscription ${SUBSCRIPTION}"
#cp myfile myfile.bak

azure config mode arm

###########################################
# Create root level resources

#Create the enclosing resource group
azure group create --name $RESOURCE_GROUP --location $LOCATION \
  --subscription $SUBSCRIPTION

#Create the virtual network

azure network vnet create --address-prefixes $VNET_IP_RANGE \
  --name $VNET_NAME --location $LOCATION $POSTFIX

# Create the storage account for diagnostics logs
azure storage account create --type LRS --location $LOCATION $POSTFIX \
  $DIAGNOSTICS_STORAGE

# Create the public IP address (dynamic)
azure network public-ip create --name $PUBLIC_IP_NAME --location $LOCATION $POSTFIX

# Create the jumpbox public IP address (dynamic)
azure network public-ip create --name $JUMPBOX_PUBLIC_IP_NAME --location $LOCATION $POSTFIX

##################################################################
# Create the web tier
# Web tier has a public IP, load balancer, availability set, and three VMs

LB_NAME="${APP_NAME}-web-lb"
SUBNET_NAME="${APP_NAME}-web-subnet"
AVAILSET_NAME="${APP_NAME}-web-as"
USING_AVAILSET=true

# Create web tier (public) load balancer
azure network lb create --name $LB_NAME --location $LOCATION $POSTFIX

# Create the subnet
azure network vnet subnet create --vnet-name $VNET_NAME --address-prefix \
$WEB_SUBNET_IP_RANGE --name $SUBNET_NAME $POSTFIX

# Create the availability sets
azure availset create --name $AVAILSET_NAME --location $LOCATION $POSTFIX

# Create the load balancer frontend-ip using the public IP address
azure network lb frontend-ip create --name $LB_NAME-frontend --lb-name \
  $LB_NAME --public-ip-name $PUBLIC_IP_NAME $POSTFIX

CreateCommonLBResources $LB_NAME

#Create VMs and per-VM resources
for ((i=1; i<=$NUM_VM_INSTANCES_WEB_TIER ; i++))
  do
    CreateVm $i web $SUBNET_NAME $USING_AVAILSET $LB_NAME
  done


###########################################################################

# Create the business tier
# Business tier has an internal load balancer, availability set, and three VMs

LB_NAME="${APP_NAME}-biz-lb"
SUBNET_NAME="${APP_NAME}-biz-subnet"
AVAILSET_NAME="${APP_NAME}-biz-as"
USING_AVAILSET=true

# Create the business tier internal load balancer
azure network lb create --name $LB_NAME --location $LOCATION $POSTFIX

# Create the subnet
azure network vnet subnet create --vnet-name $VNET_NAME --address-prefix \
  $BIZ_SUBNET_IP_RANGE --name $SUBNET_NAME $POSTFIX

# Create the availability sets
azure availset create --name $AVAILSET_NAME --location $LOCATION $POSTFIX

# Create the load balancer frontend-ip using a private IP address and subnet
azure network lb frontend-ip create --name "${LB_NAME}-frontend" --lb-name \
 $LB_NAME --private-ip-address $BIZ_ILB_IP --subnet-name $SUBNET_NAME \
 --subnet-vnet-name $VNET_NAME $POSTFIX

CreateCommonLBResources $LB_NAME

#Create VMs and per-VM resources
for ((i=1; i<=$NUM_VM_INSTANCES_BIZ_TIER ; i++))
  do
    CreateVm $i biz $SUBNET_NAME $USING_AVAILSET $LB_NAME
  done


##################################################################################
# Create the database tier
# Database tier has no load balancer, an availability set, and two VMs.

SUBNET_NAME="${APP_NAME}-db-subnet"
AVAILSET_NAME="${APP_NAME}-db-as"
USING_AVAILSET=true

# Create the subnet
azure network vnet subnet create --vnet-name $VNET_NAME --address-prefix \
 $DB_SUBNET_IP_RANGE --name $SUBNET_NAME $POSTFIX

# Create the availability sets
azure availset create --name $AVAILSET_NAME --location $LOCATION $POSTFIX

# Create VMs and per-VM resources

for ((i=1; i<=$NUM_VM_INSTANCES_DB_TIER ; i++))
  do
    CreateVm $i db $SUBNET_NAME $USING_AVAILSET
  done


#############################################################################################
# Create the management subnet
# Management subnet has no load balancer, no availability set, and one VM (jumpbox)

SUBNET_NAME="${APP_NAME}-manage-subnet"
USING_AVAILSET=false

# Create the subnet
azure network vnet subnet create --vnet-name $VNET_NAME --address-prefix \
  $MANAGE_SUBNET_IP_RANGE --name $SUBNET_NAME $POSTFIX

# Create VMs and per-VM resources


for ((i=1; i<=$NUM_VM_INSTANCES_MANAGE_TIER ; i++))
  do
    CreateVm $i manage $SUBNET_NAME $USING_AVAILSET
  done



#############################################
# Network Security Group Rules

# The Jump box NSG rule allows inbound remote access traffic from admin-address-prefix script parameter.
# To view the provisioned NSG rules, go to the portal (portal.azure.com) and view the
# Inbound and Outbound rules for the NSG.
# Don't forget that there are default rules that are also visible through the portal.

MANAGE_NSG_NAME="${APP_NAME}-manage-nsg"

azure network nsg create --name $MANAGE_NSG_NAME --location $LOCATION $POSTFIX

azure network nsg rule create --nsg-name $MANAGE_NSG_NAME --name admin-ssh-allow \
	--access Allow --protocol Tcp --direction Inbound --priority 100 \
	--source-address-prefix $ADMIN_ADDRESS_PREFIX --source-port-range "*" \
	--destination-address-prefix "*" --destination-port-range $REMOTE_ACCESS_PORT $POSTFIX

# Associate the NSG rule with the jumpbox NIC
azure network nic set --name $JUMPBOX_NIC_NAME \
	--network-security-group-name $MANAGE_NSG_NAME $POSTFIX

# Make Jump Box publically accessible
azure network nic set --name $JUMPBOX_NIC_NAME --public-ip-name $JUMPBOX_PUBLIC_IP_NAME $POSTFIX


# DB Tier NSG rule

DB_TIER_NSG_NAME="${APP_NAME}-db-nsg"

azure network nsg create --name $DB_TIER_NSG_NAME --location $LOCATION $POSTFIX

# Allow inbound traffic from business tier subnet to the DB tier
azure network nsg rule create --nsg-name $DB_TIER_NSG_NAME --name biz-allow \
	--access Allow --protocol "*" --direction Inbound --priority 100 \
	--source-address-prefix $BIZ_SUBNET_IP_RANGE --source-port-range "*" \
	--destination-address-prefix "*" --destination-port-range "*" $POSTFIX

# Allow inbound remote access traffic from management subnet
azure network nsg rule create --nsg-name $DB_TIER_NSG_NAME --name manage-ssh-allow \
	--access Allow --protocol Tcp --direction Inbound --priority 200 \
	--source-address-prefix $MANAGE_SUBNET_IP_RANGE --source-port-range "*" \
	--destination-address-prefix "*" --destination-port-range $REMOTE_ACCESS_PORT $POSTFIX

# Deny all other inbound traffic from within vnet
azure network nsg rule create --nsg-name $DB_TIER_NSG_NAME --name vnet-deny \
	--access Deny --protocol "*" --direction Inbound --priority 1000 \
	--source-address-prefix VirtualNetwork --source-port-range "*" \
	--destination-address-prefix "*" --destination-port-range "*" $POSTFIX

# Associate the NSG rule with the subnet
azure network vnet subnet set --vnet-name $VNET_NAME --name "${APP_NAME}-db-subnet" \
--network-security-group-name $DB_TIER_NSG_NAME $POSTFIX
