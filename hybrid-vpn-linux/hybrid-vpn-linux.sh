#!/bin/bash

############################################################################
# errhandle : handles errors via trap if any exception happens             # 
# in the cli execution or if the user interrupts with CTRL+C               #
# allowing for fast interruption                                           #
############################################################################

# Error handling or interruption via ctrl-c.
# Line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{ 
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

###############################################################################
############################## End of user defined functions ##################
###############################################################################

# 1 paramater is expected

if [ $# -ne 1  ]
then
	echo  "Usage:  ${0} subscription-id"
	exit
fi

# Explicitly set the subscription to avoid confusion as to which subscription
# is active/default
# ScriptCommandParameters
SUBSCRIPTION=$1

# ScriptVars
APP_NAME=hybrid
LOCATION=centralus
ENVIRONMENT=dev
VPN_GATEWAY_TYPE=RouteBased

VNET_IP_RANGE=10.20.0.0/16
ON_PREMISES_ADDRESS_SPACE=10.10.0.0/16
ON_PREMISES_PUBLIC_IP=40.50.60.70

# This gives the gateway an IP range 10.20.255.224 - 10.20.255.254
GATEWAY_SUBNET_IP_RANGE=10.20.255.224/27

# This give the internal subnet an IP range of 10.20.1.1 - 10.20.1.254
INTERNAL_SUBNET_IP_RANGE=10.20.1.0/24

# We will put this at the end of the subnet
INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS=10.20.1.254

# Set up the names of things using recommended conventions
RESOURCE_GROUP="${APP_NAME}-${ENVIRONMENT}-rg"
VNET_NAME="${APP_NAME}-vnet"
PUBLIC_IP_NAME="${APP_NAME}-pip"

INTERNAL_SUBNET_NAME="${APP_NAME}-internal-subnet"
VPN_GATEWAY_NAME="${APP_NAME}-vgw"
LOCAL_GATEWAY_NAME="${APP_NAME}-lgw"
VPN_CONNECTION_NAME="${APP_NAME}-vpn"

INTERNAL_LOAD_BALANCER_NAME="${APP_NAME}-ilb"
INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME="${APP_NAME}-ilb-fip"
INTERNAL_LOAD_BALANCER_POOL_NAME="${APP_NAME}-ilb-pool"
INTERNAL_LOAD_BALANCER_PROBE_NAME="${INTERNAL_LOAD_BALANCER_NAME}-probe"

INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL=tcp
INTERNAL_LOAD_BALANCER_PROBE_INTERVAL=300
INTERNAL_LOAD_BALANCER_PROBE_COUNT=4


# Set up the postfix variables attached to most CLI commands
POSTFIX="--resource-group ${RESOURCE_GROUP} --subscription ${SUBSCRIPTION}"

# Set up the postfix variables attached to most CLI commands

#POSTFIX="--resource-group ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}"

azure config mode arm

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Create resources

# Create the enclosing resource group
azure group create --name $RESOURCE_GROUP  --location $LOCATION --subscription $SUBSCRIPTION

# Create the VNet
azure network vnet create --address-prefixes $VNET_IP_RANGE --name $VNET_NAME --location $LOCATION $POSTFIX

# Create the GatewaySubnet
azure network vnet subnet create --vnet-name $VNET_NAME \
--address-prefix $GATEWAY_SUBNET_IP_RANGE --name GatewaySubnet $POSTFIX

# Create public IP address for VPN Gateway
# Note that the Azure VPN Gateway only supports dynamic IP addresses
azure network public-ip create --allocation-method Dynamic \
  --name $PUBLIC_IP_NAME --location $LOCATION $POSTFIX

# Create virtual network gateway
azure network vpn-gateway create --name $VPN_GATEWAY_NAME \
--vpn-type $VPN_GATEWAY_TYPE --public-ip-name $PUBLIC_IP_NAME --vnet-name $VNET_NAME \
--location $LOCATION $POSTFIX

# Create local gateway
azure network local-gateway create --name $LOCAL_GATEWAY_NAME \
--address-space $ON_PREMISES_ADDRESS_SPACE --ip-address $ON_PREMISES_PUBLIC_IP \
--location $LOCATION $POSTFIX
 
# Create a site-to-site connection
azure network vpn-connection create --name $VPN_CONNECTION_NAME \
--vnet-gateway1 $VPN_GATEWAY_NAME --vnet-gateway1-group $RESOURCE_GROUP \
--lnet-gateway2 $LOCAL_GATEWAY_NAME --lnet-gateway2-group $RESOURCE_GROUP \
--type IPsec --location $LOCATION $POSTFIX
 
# Create the internal subnet
azure network vnet subnet create --vnet-name $VNET_NAME \
--address-prefix $INTERNAL_SUBNET_IP_RANGE --name $INTERNAL_SUBNET_NAME $POSTFIX

# Create an internal load balancer for routing requests
azure network lb create --name $INTERNAL_LOAD_BALANCER_NAME \
--location $LOCATION $POSTFIX

# Create a frontend IP address for the internal load balancer
azure network lb frontend-ip create --subnet-vnet-name $VNET_NAME \
--subnet-name $INTERNAL_SUBNET_NAME \
--private-ip-address $INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS \
--lb-name $INTERNAL_LOAD_BALANCER_NAME \
--name $INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME \
$POSTFIX

# Create the backend address pool for the internal load balancer
azure network lb address-pool create --lb-name $INTERNAL_LOAD_BALANCER_NAME \
--name $INTERNAL_LOAD_BALANCER_POOL_NAME $POSTFIX

# Create a health probe for the internal load balancer
azure network lb probe create --protocol $INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL \
--interval $INTERNAL_LOAD_BALANCER_PROBE_INTERVAL --count $INTERNAL_LOAD_BALANCER_PROBE_COUNT \
--lb-name $INTERNAL_LOAD_BALANCER_NAME --name $INTERNAL_LOAD_BALANCER_PROBE_NAME $POSTFIX

# This will show the shared key for the VPN connection
azure network vpn-connection shared-key show --name $VPN_CONNECTION_NAME $POSTFIX
