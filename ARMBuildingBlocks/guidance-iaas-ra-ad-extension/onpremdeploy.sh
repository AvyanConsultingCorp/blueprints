############################################################################
## Command Arguments
############################################################################
BASE_NAME=
SUBSCRIPTION=
LOCATION=
ADMIN_USER_NAME=
ADMIN_PASSWORD=
############################################################################
RESOURCE_GROUP=${BASE_NAME}-rg
URI_BASE=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks
VM_IP_ADDRESS=192.168.0.4
AD_SUBNET_NAME_PREFIX=dns
VM_NAME_PREFIX=dns
VM_COMPUTER_NAME=dns
AD_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${AD_SUBNET_NAME_PREFIX}-sn
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
echo
echo
echo azure config mode arm
     azure config mode arm
############################################################################
## Create vnet
############################################################################
TEMPLATE_URI=${URI_BASE}/guidance-iaas-ra-ad-extension/Templates/ra-ad-extension/onprem-simulation.json
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"}}"
echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
	 
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

############################################################################
## Create vm with pip on the vnet
############################################################################
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-vm-dns-pip.json
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerName\":{\"value\":\"${VM_COMPUTER_NAME}\"},\"vmIPaddress\":{\"value\":\"${VM_IP_ADDRESS}\"},\"snid\":{\"value\":\"${AD_SUBNET_ID}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"}}"
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

############################################################################
# Install adds forest on the vm
echo -n "Verify that you can connect to dns servers"
echo
read -p "Press any key to continue... " -n1 -s

VM_NAME=${BASE_NAME}-${VM_NAME_PREFIX}-vm
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-vm-dns-forest-extension.json
PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"}}"
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
