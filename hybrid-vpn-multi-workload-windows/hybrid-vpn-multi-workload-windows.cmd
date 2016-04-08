@ECHO OFF
SETLOCAL
IF "%~2"=="" (
    ECHO Usage: %0 subscription-id ipsec-shared-key
    ECHO   For example: %0 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx xxxxxxxxxxxx
    EXIT /B
    )
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default
SET SUBSCRIPTION=%1
SET IPSEC_SHARED_KEY=%2
SET ENVIRONMENT=dev
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create hub
SET HUB_NAME=hub0
SET HUB_CIDR=10.0.0.0/16
SET HUB_INTERNAL_CIDR=10.0.0.0/17
SET HUB_GATEWAY_CIDR=10.0.255.240/28
SET HUB_GATEWAY_NAME=%HUB_NAME%-vgw
SET HUB_GATEWAY_PIP_NAME=%HUB_NAME%-pip
SET HUB_LOCATION=eastus
SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg
CALL :CREATE_VNET ^
    %HUB_NAME% ^
    %HUB_CIDR% ^
    %HUB_INTERNAL_CIDR% ^
    %HUB_GATEWAY_CIDR% ^
    %HUB_GATEWAY_NAME% ^
    %HUB_GATEWAY_PIP_NAME% ^
    %HUB_LOCATION% ^
    %HUB_RESOURCE_GROUP%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: HUB-ONPREM and ONPREM-HUB connections

SET ONPREM_NAME=on-prem
SET ONPREM_GATEWAY_PIP=131.107.36.3
SET ONPREM_CIDR=192.268.0.0/24
SET HUB_TO_ONPREM_LGW=%HUB_NAME%-to-%ONPREM_NAME%-lgw
SET HUB_TO_ONPREM_VPN-CONNECTION=%HUB_NAME%-to-%ONPREM_NAME%-vpn-connection
SET ONPREM_TO_HUB_LGW=%ONPREM_NAME%-to-%HUB_NAME%-lgw
SET ONPREM_TO_HUB_TOPOLOGY_CIDR=

:: HUB_TO_ONPREM_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %HUB_TO_ONPREM_LGW% ^
  --address-space %ONPREM_CIDR% ^
  --ip-address %ONPREM_GATEWAY_PIP% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: HUB_TO_ONPREM_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_ONPREM_VPN-CONNECTION% ^
  --vnet-gateway1 %HUB_GATEWAY% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_ONPREM_LGW% ^
  --lnet-gateway2-group %HUB_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: ONPREM_TO_HUB_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %ONPREM_TO_HUB_LGW% ^
  --address-space %ONPREM_TO_HUB_TOPOLOGY_CIDR% ^
  --ip-address %HUB_GATEWAY_PIP% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: ONPREM_TO_HUB_VPN-CONNECTION
:: this is created manually on premise 
::
::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create SP1
SET SP1_NAME=spoke1
SET SP1_CIDR=10.1.0.0/16
SET SP1_INTERNAL_CIDR=10.1.0.0/17
SET SP1_GATEWAY_CIDR=10.1.255.240/28
SET SP1_GATEWAY_NAME=%SP1_NAME%-vgw
SET SP1_GATEWAY_PIP_NAME=%SP1_NAME%-vgw
SET SP1_LOCATION=eastus
SET SP1_RESOURCE_GROUP=%SP1_NAME%-%ENVIRONMENT%-rg
SET SP1_ILB=10.1.127.254

CALL :CREATE_VNET ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_INTERNAL_CIDR% ^
    %SP1_GATEWAY_CIDR% ^
    %SP1_GATEWAY_NAME% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCATION% ^
    %SP1_RESOURCE_GROUP% ^
    %SP1_ILB%

CALL :CREATE_HUB_SPOKE_CONNECTION ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_TO_HUB_TOPOLOGY_CIDR% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCACTION% ^
    %SP1_RESOURCE_GROUP% ^

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTION
:CREATE_HUB_SPOKE_CONNECTION

:: input variableS
SPK_NAME=%SP1%
SET SPK_CIDR=%1
SET SPK_TO_HUB_TOPOLOGY_CIDR=%2
SET SPK_GATEWAY_PIP_NAME=%S3
SET SPK_LOCACTION=%4
SET SPK_RESOURCE_GROUP=%5

:: azure resource names
SET HUB_TO_SPK_LGW=%HUB_NAME%-to-%SPK_NAME%-lgw
SET HUB_TO_SPK_VPN-CONNECTION=%HUB_NAME%-to-%SPK_NAME%-vpn-connection
SET SPK_TO_HUB_LGW=%SPK_NAME%-to-%HUB_NAME%-lgw
SET SPK_TO_HUB_VPN-CONNECTION=%SPK_NAME%-to-%HUB_NAME%-vpn-connection

:: Parse public-ip json to get the line that contains an ip address.
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %SP1_RESOURCE_GROUP% -n %SPK_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET SPK_GATEWAY_PIP=%JSON_IP_ADDRESS_LINE:~16,-2%

:: Parse public-ip json to get the line that contains an ip address.
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %SP1_RESOURCE_GROUP% -n %HUB_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET HUB_GATEWAY_PIP=%JSON_IP_ADDRESS_LINE:~16,-2%

:: HUB_TO_SPK_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %HUB_TO_SPK_LGW% ^
  --address-space %SPK_CIDR% ^
  --ip-address %SPK_GATEWAY_PIP% ^
  --location %SPK_LOCACTION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: SPK_TO_HUB_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %SP1_TO_HUB_LGW% ^
  --address-space %SPK_TO_HUB_TOPOLOGY_CIDR% ^
  --ip-address %HUB_GATEWAY_PIP% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: HUB_TO_SPK_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_SPK_VPN-CONNECTION% ^
  --vnet-gateway1 %HUB_GATEWAY% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_SPK_LGW% ^
  --lnet-gateway2-group %SPK_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: SP1_TO_HUB_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --vnet-gateway1 %SP1_GATEWAY% ^
  --vnet-gateway1-group %SP1_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK_TO_HUB_LGW% ^
  --lnet-gateway2-group %HUB_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %SPK_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTION
:CREATE_VNET

:: Set up variables to build out the naming conventions for deployment
SET APP_NAME=%1
SET APP_CIDR=%2
SET APP_INTERNAL_CIDR=%3
SET APP_GATEWAY_CIDR=%4
SET APP_GATEWAY_NAME=%5
SET APP_GATEWAY_PIP_NAME=%6
SET APP_LOCATION=%7
SET APP_RESOURCE_GROUP=%8
SET INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS=%9

:: Set up the azure resource names using recommended conventions
SET APP_SUBSCRIPTION=%SUBSCRIPTION%

SET APP_VNET_NAME=%APP_NAME%-vnet
SET APP_PUBLIC_IP_NAME=%APP_NAME%-pip
SET APP_INTERNAL_SUBNET_NAME=%APP_NAME%-internal-subnet

:: Prepare Azure CLI
CALL azure config mode arm

:::::::::::::::::::::::::::::::::::::::
:: Create network resources

:: Create the enclosing resource group
CALL :CallCLI azure group create ^
  --name %APP_RESOURCE_GROUP% ^
  --location %APP_LOCATION% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the VNet
CALL :CallCLI azure network vnet create ^
  --name %APP_VNET_NAME% ^
  --address-prefixes %APP_CIDR% ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the GatewaySubnet
CALL :CallCLI azure network vnet subnet create ^
  --name GatewaySubnet ^
  --address-prefix %APP_GATEWAY_CIDR%
  --vnet-name %APP_VNET_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the internal subnet
CALL :CallCLI azure network vnet subnet create ^
  --name %APP_INTERNAL_SUBNET_NAME% ^
  --address-prefix %APP_INTERNAL_CIDR% ^
  --vnet-name %APP_VNET_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the public IP address for VPN Gateway
:: Note that the Azure VPN Gateway only supports
:: dynamic IP addresses
CALL :CallCLI azure network public-ip create ^
  --name %APP_GATEWAY_PIP_NAME% ^
  --allocation-method Dynamic ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the vpn gateway
CALL :CallCLI azure network vpn-gateway create ^
  --name %APP_GATEWAY_NAME% ^
  --type RouteBased ^
  --public-ip-name %PUBLIC_IP_NAME% ^
  --vnet-name %APP_VNET_NAME% ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:::::::::::::::::::::::::::::::::::::::
:: Create ILB resources
IF "%INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS%"=="" (
    EXIT /B
    )

SET INTERNAL_LOAD_BALANCER_NAME=%APP_NAME%-ilb
SET INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME=%APP_NAME%-ilb-fip
SET INTERNAL_LOAD_BALANCER_POOL_NAME=%APP_NAME%-ilb-pool
SET INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL=tcp
SET INTERNAL_LOAD_BALANCER_PROBE_INTERVAL=300
SET INTERNAL_LOAD_BALANCER_PROBE_COUNT=4
SET INTERNAL_LOAD_BALANCER_PROBE_NAME=%INTERNAL_LOAD_BALANCER_NAME%-probe

CALL :CallCLI azure network lb create ^
  --name %APP_INTERNAL_LOAD_BALANCER_NAME% ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create a frontend IP address for the internal load balancer
CALL :CallCLI azure network lb frontend-ip create ^
  --name %INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME% ^
  --private-ip-address %INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS% ^
  --lb-name %INTERNAL_LOAD_BALANCER_NAME% ^
  --subnet-name %INTERNAL_SUBNET_NAME% ^
  --subnet-vnet-name %APP_VNET_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create the backend address pool for the internal load balancer
CALL :CallCLI azure network lb address-pool create ^
  --lb-name %INTERNAL_LOAD_BALANCER_NAME% ^
  --name %INTERNAL_LOAD_BALANCER_POOL_NAME% 
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: Create a health probe for the internal load balancer
CALL :CallCLI azure network lb probe create ^
  --name %INTERNAL_LOAD_BALANCER_PROBE_NAME% ^
  --protocol %INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL% ^
  --interval %INTERNAL_LOAD_BALANCER_PROBE_INTERVAL% ^
  --count %INTERNAL_LOAD_BALANCER_PROBE_COUNT% ^
  --lb-name %INTERNAL_LOAD_BALANCER_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

:: This will show the shared key for the VPN connection.  We won't bother with the error checking.
CALL azure network vpn-connection shared-key show ^
  --name %VPN_CONNECTION_NAME% 
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

GOTO :eof
