@ECHO OFF
SETLOCAL
IF "%~2"=="" (
    ECHO Usage: %0 subscription-id ipsec-shared-key
    ECHO   For example: %0 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx xxxxxxxxxxxx
    EXIT /B
    )
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: this script will create a hub-and-spoke network topology which consists of
:: on-premise network
:: hub vnet
:: spoke1 vent
:: spoke2 vent
:: spoke3 vent
:: all the network traffic goes through hub
:: VMs in all vnet are two-way connected through hub. for example, you should be 
:: able to pin from a vm in spoke1 to a vm in spoke2. or from a computer in on-prem
:: network to a vm in spoke3.
::
:: Order of execution: 
::   SET globle variables
::   CALL :CREATE_HUB_VNET 
::   CALL :CREATE_SPOKE_VNET %SPK1_NAME% %SPK1_CIDR% %SPK1_GW% %SPK1_SUBNET% %SPK1_LOC% %SPK1_ILB% 
::   CALL :CREATE_SPOKE_VNET %SPK2_NAME% %SPK2_CIDR% %SPK2_GW% %SPK2_SUBNET% %SPK2_LOC% %SPK1_ILB% 
::   CALL :CREATE_SPOKE_VNET %SPK3_NAME% %SPK3_CIDR% %SPK3_GW% %SPK3_SUBNET% %SPK3_LOC% %SPK1_ILB% 
::   CALL :CREATE_SPOKE_TO_HUB_CONNECTIONS
::   CALL :CREATE_HUB_TO_SPOKE_CONNECTIONS
:: THE END
::
:: The script consists the following subroutines
::   :CREATE_HUB_VNET 
::   :CREATE_SPOKE_VNET               called one time for each spoke 
::   :CREATE_SPOKE_TO_HUB_CONNECTIONS
::   :CREATE_HUB_TO_SPOKE_CONNECTIONS
::   :CallCLI                         which put error handling for CLI command
::   :ShowError                       which pritn out the error messages
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default
SET SUBSCRIPTION=%1

SET IPSEC_SHARED_KEY=%2

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Input variables
:: Note: You can change input variables. 
:: There is no validation on the input. 
:: Make sure your input is correct!
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET ON_PREM_GATEWAY_PIP_ADDRESS=131.107.36.3

SET ON_PREM_NAME=on-prem

SET ENVIRONMENT=dev

SET HUB_NAME=hub0

SET SPK1_NAME=app1
SET SPK2_NAME=app1
SET SPK3_NAME=app3

:: network ip address range
SET ON_PREM_CIDR=192.268.0.0/24
SET HUB_CIDR=10.0.0.0/16
SET SPK1_CIDR=10.1.0.0/16
SET SPK2_CIDR=10.2.0.0/16
SET SPK3_CIDR=10.3.0.0/16

:: gateway subnet ip address range
SET HUB_GW=10.0.255.240/28
SET SPK1_GW=10.1.255.240/28
SET SPK2_GW=10.2.255.240/28
SET SPK3_GW=10.3.255.240/28

:: set subnet ip address range
SET HUB_SUBNET=10.0.0.0/17
SET SPK1_SUBNET=10.1.0.0/17
SET SPK2_SUBNET=10.2.0.0/17
SET SPK3_SUBNET=10.3.0.0/17

:: set azure region
SET HUB_LOC=eastus
SET SPK1_LOC=eastus
SET SPK2_LOC=eastus
SET SPK3_LOC=eastus

:: set internal load banlance ip address
SET SPK1_ILB=10.1.127.254
SET SPK2_ILB=10.2.127.254
SET SPK3_ILB=10.3.127.254

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Derived variable. we suggest that you don't change them
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: local gateway address space
SET SPK1_TO_HUB_LGW_CIDRS=%ON_PREM_CIDR%,%HUB_CIDR%,%SPK2_CIDR%,%SPK3_CIDR%

SET SPK2_TO_HUB_LGW_CIDRS=%ON_PREM_CIDR%,%HUB_CIDR%,%SPK1_CIDR%,%SPK3_CIDR%

SET SPK3_TO_HUB_LGW_CIDRS=%ON_PREM_CIDR%,%HUB_CIDR%,%SPK1_CIDR%,%SPK2_CIDR%

SET ON_PREM_TO_HUB_LGW_CIDRS=%HUB_CIDR%,%SPK1_CIDR%,%SPK2_CIDR%,%SPK3_CIDR%

SET HUB_TO_ON_PREM_LGW_CIDRS=%ON_PREM_CIDR%

SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg

:: vpn gateway
:: also defined in :CREATE_SPOKE sub routine as 
::  SET VPN_GATEWAY_NAME=%APP_NAME%-vgw
SET HUB_VPN_GATEWAY_NAME=%HUB_NAME%-vgw
SET SPK1_VPN_GATEWAY_NAME=%SPK1_NAME%-vgw
SET SPK2_VPN_GATEWAY_NAME=%SPK2_NAME%-vgw
SET SPK3_VPN_GATEWAY_NAME=%SPK3_NAME%-vgw

:: resource group name
:: also defined in :CREATE_SPOKE sub routine as 
:: SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg
SET SPK1_RESOURCE_GROUP=%SPK1_NAME%-%ENVIRONMENT%-rg
SET SPK2_RESOURCE_GROUP=%SPK2_NAME%-%ENVIRONMENT%-rg
SET SPK3_RESOURCE_GROUP=%SPK3_NAME%-%ENVIRONMENT%-rg

:: spoke-to-hub local gateway name
SET SPK1_TO_HUB_LGW=%SPK1_NAME%-to-%HUB_NAME%-lgw
SET SPK2_TO_HUB_LGW=%SPK2_NAME%-to-%HUB_NAME%-lgw
SET SPK3_TO_HUB_LGW=%SPK3_NAME%-to-%HUB_NAME%-lgw
SET ON_PREM_TO_HUB_LGW=%ON_PREM_NAME%-to-%HUB_NAME%-lgw

:: hub-to-spoke local gateway name
:: also defined in :CREATE_SPOKE sub routine as 
:: SET LOCAL_GATEWAY_NAME=%HUB_NAME%-to-%APP_NAME%-lgw
SET HUB_TO_ON_PREM_LGW=%HUB_NAME%-to-%ON_PREM_NAME%-lgw
SET HUB_TO_SPOKE1_LGW=%HUB_NAME%-to-%SPK1_NAME%-lgw
SET HUB_TO_SPOKE2_LGW=%HUB_NAME%-to-%SPK2_NAME%-lgw
SET HUB_TO_SPOKE3_LGW=%HUB_NAME%-to-%SPK3_NAME%-lgw

:: hub-to-spoke vpn connection name
SET HUB_TO_ON_PREM_CONECTION=%HUB_NAME%-to-%ON_PREM_NAME%-vpn
SET HUB_TO_SPK1_CONECTION=%HUB_NAME%-to-%SPK1_NAME%-vpn
SET HUB_TO_SPK2_CONECTION=%HUB_NAME%-to-%SPK2_NAME%-vpn
SET HUB_TO_SPK3_CONECTION=%HUB_NAME%-to-%SPK3_NAME%-vpn

:: spoke-to-hub vpn connection name
SET SPK1_TO_HUB_CONECTION=%SPK1_NAME%-to-%HUB_NAME%-vpn
SET SPK2_TO_HUB_CONECTION=%SPK2_NAME%-to-%HUB_NAME%-vpn
SET SPK3_TO_HUB_CONECTION=%SPK3_NAME%-to-%HUB_NAME%-vpn
SET ON_PREM_TO_HUB_CONECTION=%ON_PREM_NAME%-to-%HUB_NAME%-vpn

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create hub vnet
CALL :CREATE_HUB_VNET %HUB_CIDR% %HUB_GW% %HUB_SUBNET% %HUB_LOC% %SPK1_ILB% 

:: create spoke vnet
CALL :CREATE_SPOKE_VNET %SPK1_NAME% %SPK1_CIDR% %SPK1_GW% %SPK1_SUBNET% %SPK1_LOC% %SPK1_ILB% 
CALL :CREATE_SPOKE_VNET %SPK2_NAME% %SPK2_CIDR% %SPK2_GW% %SPK2_SUBNET% %SPK2_LOC% %SPK1_ILB% 
CALL :CREATE_SPOKE_VNET %SPK3_NAME% %SPK3_CIDR% %SPK3_GW% %SPK3_SUBNET% %SPK3_LOC% %SPK1_ILB% 

:: create spoke to hub vpn connections
CALL :CREATE_SPOKE_TO_HUB_CONNECTIONS

:: create hub to spoke vpn connections
CALL :CREATE_HUB_TO_SPOKE_CONNECTIONS

GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 1
:CREATE_HUB_VNET
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

IF "%~4"=="" (
    ECHO Usage: %0 vnet_addrss gateway_addrss subnt_adrss loc    
    ECHO   For example: %0 10.0.0.0/16 10.0.255.240/28 10.0.0.0/17 eastus 
    EXIT /B
    )

:: Set up variables to build out the naming conventions for deployment
SET APP_NAME=%HUB_NAME%
SET VNET_IP_RANGE=%1
SET GATEWAY_SUBNET_IP_RANGE=%2
SET INTERNAL_SUBNET_IP_RANGE=%3
SET LOCATION=%4

:: Set up the names of things using recommended conventions
SET VNET_NAME=%APP_NAME%-vnet
SET PUBLIC_IP_NAME=%APP_NAME%-pip

SET INTERNAL_SUBNET_NAME=%APP_NAME%-internal-subnet

SET ON_PREM_RESOURCE_GROUP=%RESOURCE_GROUP%
SET ON_PREM_LOCAL_GATEWAY=%APP_NAME%-to-%ON_PREM_NAME%-lgw

:: Set up the postfix variables attached to most CLI commands
SET POSTFIX=--resource-group %HUB_RESOURCE_GROUP% --subscription %SUBSCRIPTION%

CALL azure config mode arm

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create resources

:: Create the enclosing resource group
CALL :CallCLI azure group create --name %HUB_RESOURCE_GROUP% --location %LOCATION% ^
  --subscription %SUBSCRIPTION%

:: Create the VNet
CALL :CallCLI azure network vnet create --address-prefixes %VNET_IP_RANGE% ^
  --name %VNET_NAME% --location %LOCATION% %POSTFIX%

:: Create the GatewaySubnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %GATEWAY_SUBNET_IP_RANGE% --name GatewaySubnet %POSTFIX%

:: Create the internal subnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %INTERNAL_SUBNET_IP_RANGE% --name %INTERNAL_SUBNET_NAME% %POSTFIX%

:: Create public IP address for VPN Gateway
:: Note that the Azure VPN Gateway only supports dynamic IP addresses
CALL :CallCLI azure network public-ip create --allocation-method Dynamic ^
  --name %PUBLIC_IP_NAME% --location %LOCATION% %POSTFIX%

:: Create virtual network gateway
CALL :CallCLI azure network vpn-gateway create --name %HUB_VPN_GATEWAY_NAME% ^
  --type RouteBased --public-ip-name %PUBLIC_IP_NAME% --vnet-name %VNET_NAME% ^
  --location %LOCATION% %POSTFIX

:: Parse public-ip json to get the line that contains an ip address. 
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %HUB_RESOURCE_GROUP% -n %PUBLIC_IP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET VPN_GATEWAY_PIP_ADDRESS=%JSON_IP_ADDRESS_LINE:~16,-2%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 2
:CREATE_HUB_LOCAL_GATEWAYS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create in-comming local gateways to hub. 
:: The gateways are used in:CREATE_SPOKE_VNET subroutine

:: Create local gateway SPK1_TO_HUB_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %SPK1_TO_HUB_LGW% ^
  --address-space %SPK1_TO_HUB_LGW_CIDRS% ^
  --ip-address %VPN_GATEWAY_PIP_ADDRESS% ^
  --location %HUB_LOC% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create local gateway SPK1_TO_HUB_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %SPK1_TO_HUB_LGW% ^
  --address-space %SPK1_TO_HUB_LGW_CIDRS% ^
  --ip-address %VPN_GATEWAY_PIP_ADDRESS% ^
  --location %HUB_LOC% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create local gateway SPK1_TO_HUB_LGW
CALL :CallCLI azure network local-gateway create ^
  --name %SPK1_TO_HUB_LGW% ^
  --address-space %SPK1_TO_HUB_LGW_CIDRS% ^
  --ip-address %VPN_GATEWAY_PIP_ADDRESS% ^
  --location %HUB_LOC% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create local gateway ON_PREM_TO_HUB_LGW
:: ON_PREM_TO_HUB_LGW will be used by the on premise gateway to connect to azure vnet
:: you need the VPN_GATEWAY_PIP_ADDRESS and ON_PREM_TO_HUB_LGW_CIDRS values
:: to config the on premise gateway
CALL :CallCLI azure network local-gateway create --name %ON_PREM_TO_HUB_LGW% ^
  --address-space %ON_PREM_TO_HUB_LGW_CIDRS% --ip-address %VPN_GATEWAY_PIP_ADDRESS% ^
  --location %LOCATION% %POSTFIX%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create out-going local gateway from hub to on premise network
:: Note:  out-going local gateway to other vnets are created in :CREATE_SPOKE_VNET subroutine

:: Create local gateway HUB_TO_ON_PREM_LGW
CALL :CallCLI azure network local-gateway create --name %HUB_TO_ON_PREM_LGW% ^
  --address-space %HUB_TO_ON_PREM_LGW_CIDRS% --ip-address %ON_PREM_GATEWAY_PIP_ADDRESS% ^
  --location %LOCATION% %POSTFIX%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 2
:CREATE_SPOKE_VNET
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF "%~6"=="" (
    ECHO Usage: %0 app vnet_addrss gateway_addrss subnt_adrss loc connect_to_lgw ilb_fe_ip
    ECHO   For example: %0 app1 app1 10.1.0.0/16 10.1.255.240/28 10.1.0.0/17 eastus app1_to_hub_lgw 10.1.127.254
    EXIT /B
    )

:: Set up variables to build out the naming conventions for deployment
SET APP_NAME=%1
SET VNET_IP_RANGE=%2
SET GATEWAY_SUBNET_IP_RANGE=%3
SET INTERNAL_SUBNET_IP_RANGE=%4
SET LOCATION=%5
SET INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS=%6

:: Set up the names of things using recommended conventions
SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg
SET VNET_NAME=%APP_NAME%-vnet
SET PUBLIC_IP_NAME=%APP_NAME%-pip

SET INTERNAL_SUBNET_NAME=%APP_NAME%-internal-subnet
SET VPN_GATEWAY_NAME=%APP_NAME%-vgw
SET LOCAL_GATEWAY_NAME=%HUB_NAME%-to-%APP_NAME%-lgw
SET VPN_CONNECTION_NAME=%APP_NAME%-to-%HUB_NAME%-vpn

SET INTERNAL_LOAD_BALANCER_NAME=%APP_NAME%-ilb
SET INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME=%APP_NAME%-ilb-fip
SET INTERNAL_LOAD_BALANCER_POOL_NAME=%APP_NAME%-ilb-pool

SET INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL=tcp
SET INTERNAL_LOAD_BALANCER_PROBE_INTERVAL=300
SET INTERNAL_LOAD_BALANCER_PROBE_COUNT=4
SET INTERNAL_LOAD_BALANCER_PROBE_NAME=%INTERNAL_LOAD_BALANCER_NAME%-probe

:: Set up the postfix variables attached to most CLI commands
SET POSTFIX=--resource-group %RESOURCE_GROUP% --subscription %SUBSCRIPTION%

CALL azure config mode arm

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create resources

:: Create the enclosing resource group
CALL :CallCLI azure group create --name %RESOURCE_GROUP% --location %LOCATION% ^
  --subscription %SUBSCRIPTION%

:: Create the VNet
CALL :CallCLI azure network vnet create --address-prefixes %VNET_IP_RANGE% ^
  --name %VNET_NAME% --location %LOCATION% %POSTFIX%

:: Create the internal subnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %INTERNAL_SUBNET_IP_RANGE% --name %INTERNAL_SUBNET_NAME% %POSTFIX%

:: Create the GatewaySubnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %GATEWAY_SUBNET_IP_RANGE% --name GatewaySubnet %POSTFIX%

:: Create public IP address for VPN Gateway
:: Note that the Azure VPN Gateway only supports dynamic IP addresses
CALL :CallCLI azure network public-ip create --allocation-method Dynamic ^
  --name %PUBLIC_IP_NAME% --location %LOCATION% %POSTFIX%

:: Create virtual network gateway
CALL :CallCLI azure network vpn-gateway create --name %VPN_GATEWAY_NAME% ^
  --type RouteBased --public-ip-name %PUBLIC_IP_NAME% --vnet-name %VNET_NAME% ^
  --location %LOCATION% %POSTFIX

:: Parse public-ip json to get the line that contains an ip address. 
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %RESOURCE_GROUP% -n %PUBLIC_IP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET VPN_GATEWAY_PIP_ADDRESS=%JSON_IP_ADDRESS_LINE:~16,-2%

:: Create local gateway
CALL :CallCLI azure network local-gateway create --name %LOCAL_GATEWAY_NAME% ^
  --address-space %VNET_IP_RANGE% --ip-address %VPN_GATEWAY_PIP_ADDRESS% ^
  --location %LOCATION% %POSTFIX%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create ILB

CALL :CallCLI azure network lb create --name %INTERNAL_LOAD_BALANCER_NAME% ^
  --location %LOCATION% %POSTFIX%

:: Create a frontend IP address for the internal load balancer
CALL :CallCLI azure network lb frontend-ip create --subnet-vnet-name %VNET_NAME% ^
  --subnet-name %INTERNAL_SUBNET_NAME% ^
  --private-ip-address %INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS% ^
  --lb-name %INTERNAL_LOAD_BALANCER_NAME% ^
  --name %INTERNAL_LOAD_BALANCER_FRONTEND_IP_NAME% ^
  %POSTFIX%

:: Create the backend address pool for the internal load balancer
CALL :CallCLI azure network lb address-pool create --lb-name %INTERNAL_LOAD_BALANCER_NAME% ^
  --name %INTERNAL_LOAD_BALANCER_POOL_NAME% %POSTFIX%

:: Create a health probe for the internal load balancer
CALL :CallCLI azure network lb probe create --protocol %INTERNAL_LOAD_BALANCER_PROBE_PROTOCOL% ^
  --interval %INTERNAL_LOAD_BALANCER_PROBE_INTERVAL% --count %INTERNAL_LOAD_BALANCER_PROBE_COUNT% ^
  --lb-name %INTERNAL_LOAD_BALANCER_NAME% --name %INTERNAL_LOAD_BALANCER_PROBE_NAME% %POSTFIX%

:: This will show the shared key for the VPN connection.  We won't bother with the error checking.
CALL azure network vpn-connection shared-key show --name %VPN_CONNECTION_NAME% %POSTFIX%

GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 3
:CREATE_SPOKE_TO_HUB_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Create SPK1_TO_HUB_CONECTION vpn connection
CALL :CallCLI azure network vpn-connection create ^
  --name %SPK1_TO_HUB_CONECTION% ^
  --vnet-gateway1 %SPK1_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %SPK1_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK1_TO_HUB_LGW% ^
  --lnet-gateway2-group %sSPK1_RESOURCE_GROUP% ^
  --type IPsec --location %SPK1_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %SPK1_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create SPK2_TO_HUB_CONECTION vpn connection
CALL :CallCLI azure network vpn-connection create ^
  --name %SPK2_TO_HUB_CONECTION% ^
  --vnet-gateway1 %SPK2_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %SPK2_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK2_TO_HUB_LGW% ^
  --lnet-gateway2-group %sSPK2_RESOURCE_GROUP% ^
  --type IPsec --location %SPK2_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %SPK2_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create SPK3_TO_HUB_CONECTION vpn connection
CALL :CallCLI azure network vpn-connection create ^
  --name %SPK3_TO_HUB_CONECTION% ^
  --vnet-gateway1 %SPK3_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %SPK3_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK3_TO_HUB_LGW% ^
  --lnet-gateway2-group %sSPK3_RESOURCE_GROUP% ^
  --type IPsec --location %SPK3_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %SPK3_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create ON_PREM_TO_HUB_CONECTION vpn connection
:: TBD manually ...
:: You need to go to the on premise gateway to set up the connection

GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 4
:CREATE_HUB_TO_SPOKE_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create HUB_TO_ON_PREM_CONECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_ON_PREM_CONECTION% ^
  --vnet-gateway1 %HUB_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_ON_PREM_LGW% ^
  --lnet-gateway2-group %HUB_RESOURCE_GROUP% ^
  --type IPsec --location %HUB_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create HUB_TO_SPK1_CONECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_SPK1_CONECTION% ^
  --vnet-gateway1 %HUB_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_SPK1_LGW% ^
  --lnet-gateway2-group %SPK1_RESOURCE_GROUP% ^
  --type IPsec --location %HUB_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create HUB_TO_SPK2_CONECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_SPK2_CONECTION% ^
  --vnet-gateway1 %HUB_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_SPK2_LGW% ^
  --lnet-gateway2-group %SPK2_RESOURCE_GROUP% ^
  --type IPsec --location %HUB_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create HUB_TO_SPK3_CONECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_SPK3_CONECTION% ^
  --vnet-gateway1 %HUB_VPN_GATEWAY_NAME% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_SPK3_LGW% ^
  --lnet-gateway2-group %SPK3_RESOURCE_GROUP% ^
  --type IPsec --location %HUB_LOC% ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 5
:CallCLI
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL
CALL %*
IF ERRORLEVEL 1 (
    CALL :ShowError "Error executing CLI Command: " %*
    :: This executes in the CALLER'S context, so we can exit the whole script on an error
    (GOTO) 2>NULL & GOTO :eof
)
GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUB ROUTION 6
:ShowError
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL EnableDelayedExpansion
:: Print the message
ECHO %~1
SHIFT
:: Get the first part of the azure CLI command so we don't have an extra space at the beginning
SET CLICommand=%~1
SHIFT
:: Loop through the rest of the parameters and recreate the CLI command
:Loop
    IF "%~1"=="" GOTO Continue
    SET "CLICommand=!CLICommand! %~1"
    SHIFT
GOTO Loop
:Continue
ECHO %CLICommand%
GOTO :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
