#!/bin/bash

############################################################################
#script for generating infrastructure for single VM running linux          #
# of user choice. It creates azure resource group, storage account for VM  #
# vnet, subnets for VM, and NSG rule                                       #
# tags for main variables used                                             #
# ScriptCommandParameters                                                  #
# ScriptVars                                                               #
############################################################################

############################################################################
# User defined functions for single VM script                              #
# errhandle : handles errors via trap if any exception happens             #
# in the cli execution or if the user interrupts with CTRL+C               #
# allowing for fast interruption                                           #
############################################################################

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

###############################################################################
############################## End of user defined functions ##################
###############################################################################

# 2 paramaters are expected
# public key file needs to be generates ssh-keygen

if [ $# -ne 2  ]
then
	echo  "Usage:  ${0}  subscription-id public-ssh-key-file"
	exit
fi

if [ ! -f $2  ]
then
	echo "Public Key file ${2} does not exist. please generate it"
	echo "ssh-keygen -t rsa -b 2048"
	exit
fi

# Explicitly set the subscription to avoid confusion as to which subscription
# is active/default
# ScriptCommandParameters
SUBSCRIPTION=$1
PUBLICKEYFILE=$2

# ScriptVars
LOCATION=eastus2
APP_NAME=app206
ENVIRONMENT=dev
USERNAME=testuser
VM_NAME="${APP_NAME}-vm1"
RESOURCE_GROUP="${APP_NAME}-${ENVIRONMENT}-rg"
IP_NAME="${APP_NAME}-pip"
NIC_NAME="${VM_NAME}-1nic"
NSG_NAME="${APP_NAME}-nsg"
SUBNET_NAME="${APP_NAME}-subnet"
VNET_NAME="${APP_NAME}-vnet"
VHD_STORAGE="${VM_NAME//-}st1"
DIAGNOSTICS_STORAGE="${VM_NAME//-}diag"

# Use the following command to get the list of URNs for RHEL, UBUNTU, and OPENSUSE:
# RHEL
# azure vm image list $LOCATION  redhat RHEL 7.2
# UBUNTU
# azure vm image list $LOCATION canonical ubuntuserver 14.04.3-LTS
# SUSE
# azure vm image $LOCATION  suse opensuse 13.2

LINUX_BASE_IMAGE=redhat:rhel:7.2:7.2.20160302

# For a list of VM sizes see: 
#   https://azure.microsoft.com/documentation/articles/virtual-machines-size-specs/
# To see the VM sizes available in a region:
# 	azure vm sizes --location <location>
VM_SIZE=Standard_DS1

# Set up the postfix variables attached to most CLI commands

POSTFIX="--resource-group ${RESOURCE_GROUP} --subscription ${SUBSCRIPTION}"

azure config mode arm

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#Create resources

#Create the enclosing resource group
azure group create --name $RESOURCE_GROUP --location $LOCATION --subscription $SUBSCRIPTION

# Create the VNet
azure network vnet create --address-prefixes 172.17.0.0/16 --name $VNET_NAME \
--location $LOCATION $POSTFIX

#Create the network security group
azure network nsg create --name $NSG_NAME --location $LOCATION $POSTFIX

#Create the subnet

azure network vnet subnet create --vnet-name $VNET_NAME --address-prefix  "172.17.0.0/24" \
--name $SUBNET_NAME --network-security-group-name $NSG_NAME $POSTFIX

#Create the public IP address (dynamic)
azure network public-ip create --name $IP_NAME --domain-name-label $VM_NAME \
--location $LOCATION $POSTFIX

#Create the NIC
azure network nic create --public-ip-name $IP_NAME --subnet-name $SUBNET_NAME \
--subnet-vnet-name $VNET_NAME --name $NIC_NAME --location $LOCATION $POSTFIX

#Create the storage account for the OS VHD
azure storage account create --type PLRS --location $LOCATION $POSTFIX $VHD_STORAGE

#Create the storage account for diagnostics logs
azure storage account create --type LRS --location $LOCATION $POSTFIX $DIAGNOSTICS_STORAGE

#Create the VM
azure vm create --name $VM_NAME --os-type Linux --image-urn  $LINUX_BASE_IMAGE \
--vm-size $VM_SIZE --vnet-subnet-name $SUBNET_NAME --vnet-name $VNET_NAME \
--nic-name $NIC_NAME --storage-account-name $VHD_STORAGE \
--os-disk-vhd "${VM_NAME}-osdisk.vhd" --admin-username $USERNAME \
--ssh-publickey-file $PUBLICKEYFILE --boot-diagnostics-storage-uri \
"https://${DIAGNOSTICS_STORAGE}.blob.core.windows.net/" --location $LOCATION $POSTFIX

#Attach a data disk
azure vm disk attach-new --vm-name $VM_NAME --size-in-gb 128 --vhd-name data1.vhd \
--storage-account-name $VHD_STORAGE $POSTFIX

#Allow SSH
azure network nsg rule create --nsg-name $NSG_NAME --direction Inbound --protocol Tcp \
--destination-port-range 22  --source-port-range "*"  --priority 100 --access Allow \
SSHAllow $POSTFIX

#Install patching extension
PATCH_CONFIG='{"rebootAfterPatch":"RebootIfNeed","startTime":"3:00","dayOfWeek":"Sunday","category":"ImportantAndRecommended"}'
azure vm extension set --name OSPatchingForLinux --publisher-name Microsoft.OSTCExtensions \
--public-config $PATCH_CONFIG --vm-name $VM_NAME --version 2.0 $POSTFIX
