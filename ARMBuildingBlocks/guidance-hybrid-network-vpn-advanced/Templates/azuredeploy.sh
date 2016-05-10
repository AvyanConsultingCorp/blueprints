
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
APP_NAME=$1
SUBSCRIPTION=$2
VPN_IPSEC_SHARED_KEY=$3
ON_PREMISES_PUBLIC_IP=$4
ON_PREMISES_ADDRESS_SPACE=$5

LOCATION=centralus
azure config mode arm

## create network 
RESOURCE_GROUP=${APP_NAME}-ntwk-rg
vnet6subnetsTemplate=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-vnet-6subnets.json
azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
parameters="{\"baseName\":{\"value\":\"app2\"},\"onpremNetPrefix\":{\"value\":\"192.168.0.0/24\"},\"vnetPrefix\":{\"value\":\"10.0.0.0/16\"},\"vnetManageSubnetPrefix\":{\"value\":\"10.0.0.0/24\"},\"vnetNvaFeSubnetPrefix\":{\"value\":\"10.0.1.0/24\"},\"vnetNvaBeSubnetPrefix\":{\"value\":\"10.0.2.0/24\"},\"vnetWebSubnetPrefix\":{\"value\":\"10.0.3.0/24\"},\"vnetBizSubnetPrefix\":{\"value\":\"10.0.4.0/24\"},\"vnetDbSubnetPrefix\":{\"value\":\"10.0.5.0/24\"}}"
azure group deployment create --template-uri ${vnet6subnetsTemplate} -g ${RESOURCE_GROUP} -p ${parameters}
##azure group deployment create --template-uri ${vnet6subnetsTemplate} -g ${RESOURCE_GROUP} -e azuredeploy.param.json 

## create web vms and ILB
##RESOURCE_GROUP=${APP_NAME}-sn-web-rg
##webTemplate=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
##azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
##azure group deployment create --template-uri ${webTemplate} -g ${RESOURCE_GROUP} -e azuredeploy.param.json 


