::@ECHO OFF
SETLOCAL

IF "%~2"=="" (
    ECHO Usage: %0 subscription-id ipsec-shared-key
    ECHO   For example: %0 13ed86531-1602-4c51-a4d4-afcfc38ddad3 mytestabc123
    EXIT /B
    )

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default
SET SUBSCRIPTION=%1
SET IPSEC_SHARED_KEY=%2
SET ENVIRONMENT=dev

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Modify data about your hub-and-spoke topology here. 
:: Only modify the values, do not modify the variable names.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET prefix=my
:::::::::::::::::::::::::::::::::::::::
:: on-prem network ONP data
SET ONP_NAME=%prefix%-onp
SET ONP_GATEWAY_PIP=131.107.36.3
SET ONP_CIDR=192.268.0.0/24
SET ONP_LOCACTION =%HUB_LOCATION%
SET ONP_RESOURCE_GROUP=%HUB_RESOURCE_GROPU%
:::::::::::::::::::::::::::::::::::::::
:: hub vnet data
SET HUB_NAME=%prefix%-hub
SET HUB_CIDR=10.0.0.0/16
SET HUB_INTERNAL_CIDR=10.0.0.0/17
SET HUB_GATEWAY_CIDR=10.0.255.224/27
SET HUB_GATEWAY_NAME=%HUB_NAME%-vgw
SET HUB_GATEWAY_PIP_NAME=%HUB_NAME%-pip
SET HUB_LOCATION=eastus
SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg
:::::::::::::::::::::::::::::::::::::::
:: spoke vnet SP1 data
SET SP1_NAME=%prefix%-sp1
SET SP1_CIDR=10.1.0.0/16
SET SP1_INTERNAL_CIDR=10.1.0.0/17
SET SP1_GATEWAY_CIDR=10.1.255.224/27
SET SP1_GATEWAY_NAME=%SP1_NAME%-vgw
SET SP1_GATEWAY_PIP_NAME=%SP1_NAME%-vgw
SET SP1_LOCATION=eastus
SET SP1_RESOURCE_GROUP=%SP1_NAME%-%ENVIRONMENT%-rg
SET SP1_ILB=10.1.127.254
:::::::::::::::::::::::::::::::::::::::
:: spoke vnet SP2 data
SET SP2_NAME=%prefix%-sp2
SET SP2_CIDR=10.2.0.0/16
SET SP2_INTERNAL_CIDR=10.2.0.0/17
SET SP2_GATEWAY_CIDR=10.2.255.224/27
SET SP2_GATEWAY_NAME=%SP2_NAME%-vgw
SET SP2_GATEWAY_PIP_NAME=%SP2_NAME%-vgw
SET SP2_LOCATION=eastus
SET SP2_RESOURCE_GROUP=%SP2_NAME%-%ENVIRONMENT%-rg
SET SP2_ILB=10.2.127.254
:::::::::::::::::::::::::::::::::::::::
:: spoke vnet SP3 data
SET SP3_NAME=%prefix%-sp3
SET SP3_CIDR=10.3.0.0/16
SET SP3_INTERNAL_CIDR=10.3.0.0/17
SET SP3_GATEWAY_CIDR=10.3.255.224/27
SET SP3_GATEWAY_NAME=%SP3_NAME%-vgw
SET SP3_GATEWAY_PIP_NAME=%SP3_NAME%-vgw
SET SP3_LOCATION=eastus
SET SP3_RESOURCE_GROUP=%SP3_NAME%-%ENVIRONMENT%-rg
SET SP3_ILB=10.3.127.254
:::::::::::::::::::::::::::::::::::::::
:: Set gateway address space CIDR list
:: You need enclose the CIDR list in quotes because they are comma seperated, 
:: If without the quotes, the script subroutine will treat each CIDR as a seperate variable.
::
:: All the lists need to be modified if you add or remove a spoke from the topology.
::
SET ONP_TO_HUB_CIDR_LIST="%HUB_CIDR%,%SP1_CIDR%,%SP2_CIDR%,%SP3_CIDR%"

SET SP1_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP2_CIDR%,%SP3_CIDR%"

SET SP2_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP3_CIDR%"

SET SP3_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP2_CIDR%"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET ADD_ADDITIONAL_SPOKE_4=FALSE

IF "%ADD_ADDITIONAL_SPOKE_4%"=="FALSE" (
  :: this is for initial hub-spoke topology setup with 
  :: one on-prem net, one hub, and three spokes.
  :: 
  :: It will first create vNets for HUB, and the spokes SP1, SP2, and SP3, 
  :: and then connects all the spokes including the on-prem spoke to and from the hub
  ::
  :: Create hub vnet
  CALL :CREATE_VNET ^
    %HUB_NAME% ^
    %HUB_CIDR% ^
    %HUB_INTERNAL_CIDR% ^
    %HUB_GATEWAY_CIDR% ^
    %HUB_GATEWAY_NAME% ^
    %HUB_GATEWAY_PIP_NAME% ^
    %HUB_LOCATION% ^
    %HUB_RESOURCE_GROUP%

  :: Create spoke vnet SP1 
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

  :: Create spoke vnet SP2
  CALL :CREATE_VNET ^
    %SP2_NAME% ^
    %SP2_CIDR% ^
    %SP2_INTERNAL_CIDR% ^
    %SP2_GATEWAY_CIDR% ^
    %SP2_GATEWAY_NAME% ^
    %SP2_GATEWAY_PIP_NAME% ^
    %SP2_LOCATION% ^
    %SP2_RESOURCE_GROUP% ^
    %SP2_ILB%

  :: Create spoke vnet SP3
  CALL :CREATE_VNET ^
    %SP3_NAME% ^
    %SP3_CIDR% ^
    %SP3_INTERNAL_CIDR% ^
    %SP3_GATEWAY_CIDR% ^
    %SP3_GATEWAY_NAME% ^
    %SP3_GATEWAY_PIP_NAME% ^
    %SP3_LOCATION% ^
    %SP3_RESOURCE_GROUP% ^
    %SP3_ILB%

  :: Connect ONP, SP1, SP2 and SP3 to and from HUB
    CALL :CONNECT_ONP_AND_SP_1_2_3_TO_AND_FROM_HUB
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

IF "%ADD_ADDITIONAL_SPOKE_4%" == "TRUE" (

  :: If you have already created the above hub spoke topology which consists of
 :: ONP, HUB, SP1, SP2, and SP3, and now you want 
  :: to add an addtion spoke SP4, you have to delete all the exisiting 
  :: vpn connections and gateways and then recreate them. Here are the steps:
  :::::::::::::::::::::::::::::::::::::::
  :: 1. Change the variable value for ADD_ADDITIONAL_SPOKE_4 from FALSE to TRUE

  :: 2. Put your data about SP4 here:
  SET SP4_NAME=%prefix%-sp4
  SET SP4_CIDR=10.4.0.0/16
  SET SP4_INTERNAL_CIDR=10.4.0.0/17
  SET SP4_GATEWAY_CIDR=10.4.255.224/27
  SET SP4_GATEWAY_NAME=%SP4_NAME%-vgw
  SET SP4_GATEWAY_PIP_NAME=%SP4_NAME%-vgw
  SET SP4_LOCATION=eastus
  SET SP4_RESOURCE_GROUP=%SP4_NAME%-%ENVIRONMENT%-rg
  SET SP4_ILB=10.4.127.254

  :: 3. Modify all the existing gateway address space list by adding ,%SP4_CIDR% at the end
  SET ONP_TO_HUB_CIDR_LIST="%HUB_CIDR%,%SP1_CIDR%,%SP2_CIDR%,%SP3_CIDR%,%SP4_CIDR%"
  SET SP1_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP2_CIDR%,%SP3_CIDR,%SP4_CIDR%"
  SET SP2_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP3_CIDR,%SP4_CIDR%"
  SET SP3_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP2_CIDR,%SP4_CIDR%"

  :: 4. Set SP4_TO_HUB_CIDR_LIST
  SET SP4_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP2_CIDR,%SP3_CIDR%"

  :: 5. Create spoke vnet SP4
  CALL :CREATE_VNET ^
    %SP4_NAME% ^
    %SP4_CIDR% ^
    %SP4_INTERNAL_CIDR% ^
    %SP4_GATEWAY_CIDR% ^
    %SP4_GATEWAY_NAME% ^
    %SP4_GATEWAY_PIP_NAME% ^
    %SP4_LOCATION% ^
    %SP4_RESOURCE_GROUP% ^
    %SP4_ILB%

  :: 6. Delete all existing vpn connections
  CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS ^
    %ONP_NAME% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

  CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS ^
    %SP1_NAME% ^
    %SP1_RESOURCE_GROUP%

  CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS ^
    %SP2_NAME% ^
    %SP2_RESOURCE_GROUP%

  CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS ^
    %SP3_NAME% ^
    %SP3_RESOURCE_GROUP%

  :: 7. Delete all existing vpn gateways
  CALL :DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_VPN_GATEWAYS ^
    %ONP_NAME% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem
  CALL :DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_VPN_GATEWAYS ^
    %SP1_NAME% ^
    %SP1_RESOURCE_GROUP% 

  CALL :DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_VPN_GATEWAYS ^
    %SP2_NAME% ^
    %SP2_RESOURCE_GROUP% 

  CALL :DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_VPN_GATEWAYS ^
    %SP3_NAME% ^
    %SP3_RESOURCE_GROUP%

  :: 8. Re-Connect ONP, SP1, SP2 and SP3 to and from HUB
  CALL :CONNECT_ONP_AND_SP_1_2_3_TO_AND_FROM_HUB

  :: 9. Connect SP4 to and from HUB
  CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP4_NAME% ^
    %SP4_CIDR% ^
    %SP4_TO_HUB_CIDR_LIST% ^
    %SP4_GATEWAY_PIP_NAME% ^
    %SP4_LOCACTION% ^
    %SP4_RESOURCE_GROUP%
) 

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS

:: input variable
SET SPK_NAME=%1
SET SPK_RESOURCE_GROUP=%2
SET ON_PREM_FLAG=%3

:: azure resource names
SET HUB_TO_SPK_LGW=%HUB_NAME%-to-%SPK_NAME%-lgw
SET HUB_TO_SPK_VPN-CONNECTION=%HUB_NAME%-to-%SPK_NAME%-vpn-connection
SET SPK_TO_HUB_LGW=%SPK_NAME%-to-%HUB_NAME%-lgw
SET SPK_TO_HUB_VPN-CONNECTION=%SPK_NAME%-to-%HUB_NAME%-vpn-connection

:: HUB_TO_SPK_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection delete ^
  --name %HUB_TO_SPK_VPN-CONNECTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

IF NOT "%ON_PREM_FLAG%" == "on_prem" (
  CALL :CallCLI azure network vpn-connection delete ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite
)

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
:DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_VPN_GATEWAYS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: input variable
SET SPK_NAME=%1
SET SPK_RESOURCE_GROUP=%2
SET ON_PREM_FLAG=%3

:: azure resource names
SET HUB_TO_SPK_LGW=%HUB_NAME%-to-%SPK_NAME%-lgw
SET HUB_TO_SPK_VPN-CONNECTION=%HUB_NAME%-to-%SPK_NAME%-vpn-connection

SET SPK_TO_HUB_LGW=%SPK_NAME%-to-%HUB_NAME%-lgw
SET SPK_TO_HUB_VPN-CONNECTION=%SPK_NAME%-to-%HUB_NAME%-vpn-connection

:: HUB_TO_SPK_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %HUB_TO_SPK_LGW% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

:: SPK_TO_HUB_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %SPK_TO_HUB_LGW% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
:CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: input variable
SET SPK_NAME=%1
SET SPK_CIDR=%2
SET SPK_TO_HUB_CIDR_LIST=%3
SET SPK_TO_HUB_CIDR_LIST=%SPK_TO_HUB_CIDR_LIST:~1,-1%
SET SPK_GATEWAY_PIP_NAME=%4
SET SPK_LOCACTION=%5
SET SPK_RESOURCE_GROUP=%6
SET ON_PREM_FLAG=%7

:: azure resource names
SET HUB_TO_SPK_LGW=%HUB_NAME%-to-%SPK_NAME%-lgw
SET HUB_TO_SPK_VPN-CONNECTION=%HUB_NAME%-to-%SPK_NAME%-vpn-connection

SET SPK_TO_HUB_LGW=%SPK_NAME%-to-%HUB_NAME%-lgw
SET SPK_TO_HUB_VPN-CONNECTION=%SPK_NAME%-to-%HUB_NAME%-vpn-connection

:::::::::::::::::::::::::::::::::::::::
:: Retrieve SPK_GATEWAY_PIP

IF "%ON_PREM_FLAG%" == "on_prem" (
    SET SPK_GATEWAY_PIP=%SPK_GATEWAY_PIP_NAME%
) ELSE (
    :: Parse public-ip json to get the line that contains an ip address.
    :: There is only one line that consists the ip address
    FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %SPK_RESOURCE_GROUP% -n %SPK_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

    :: Remove the first 16 and last two charactors to get the ip address
    SET SPK_GATEWAY_PIP=%JSON_IP_ADDRESS_LINE:~16,-2%
)

:::::::::::::::::::::::::::::::::::::::
:: Retrieve HUB_GATEWAY_PIP

:: Parse public-ip json to get the line that contains an ip address.
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %SPK_RESOURCE_GROUP% -n %HUB_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET HUB_GATEWAY_PIP=%JSON_IP_ADDRESS_LINE:~16,-2%

:::::::::::::::::::::::::::::::::::::::
:: Create vpn gateways

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
  --name %SPK_TO_HUB_LGW% ^
  --address-space %SPK_TO_HUB_CIDR_LIST% ^
  --ip-address %HUB_GATEWAY_PIP% ^
  --location %HUB_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:::::::::::::::::::::::::::::::::::::::
:: Create site-to-site vpn connections

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

:: SPK_TO_HUB_VPN-CONNECTION
:: You do not create on-prem to hub connection in azure. 
:: Instead, you need to go to on premise network
:: to route the traffic to the hub gateway pip.
IF NOT "%ON_PREM_FLAG%" == "on_prem" (
  CALL :CallCLI azure network vpn-connection create ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --vnet-gateway1 %SPK_GATEWAY% ^
  --vnet-gateway1-group %SPK_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK_TO_HUB_LGW% ^
  --lnet-gateway2-group %HUB_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %SPK_LOCACTION% ^
  --resource-group %HUB_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%
)

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
:CREATE_VNET
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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
  --address-prefix %APP_GATEWAY_CIDR% ^
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
  --name %INTERNAL_LOAD_BALANCER_POOL_NAME% ^
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
  --name %VPN_CONNECTION_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
:CONNECT_ONP_AND_SP_1_2_3_TO_AND_FROM_HUB
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ONP_TO_HUB_TO_ONP connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %ONP_NAME% ^
    %ONP_CIDR% ^
    %ONP_TO_HUB_CIDR_LIST% ^
    %ONP_GATEWAY_PIP% ^
    %ONP_LOCACTION% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

:::::::::::::::::::::::::::::::::::::::
:: SP1_TO_HUB_TO_SP1 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_TO_HUB_CIDR_LIST% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCACTION% ^
    %SP1_RESOURCE_GROUP%

:::::::::::::::::::::::::::::::::::::::
:: SP2_TO_HUB_TO_SP2 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP2_NAME% ^
    %SP2_CIDR% ^
    %SP2_TO_HUB_CIDR_LIST% ^
    %SP2_GATEWAY_PIP_NAME% ^
    %SP2_LOCACTION% ^
    %SP2_RESOURCE_GROUP%

:::::::::::::::::::::::::::::::::::::::
:: SP3_TO_HUB_SP3 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP3_NAME% ^
    %SP3_CIDR% ^
    %SP3_TO_HUB_CIDR_LIST% ^
    %SP3_GATEWAY_PIP_NAME% ^
    %SP3_LOCACTION% ^
    %SP3_RESOURCE_GROUP%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
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
:: SUBROUTINE
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
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
