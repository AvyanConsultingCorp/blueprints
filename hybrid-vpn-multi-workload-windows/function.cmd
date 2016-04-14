:: function.cmd
:: Functions defined in this file:
::   :LOAD_DEFAULT_DATA
::   :CREATE_DEFAULT_VNETS
::   :CREATE_DEFAULT_VPN_CONNECTIONS
::   :DELETE_DEFAULT_VPN_CONNECTIONS

::   :CREATE_VNET
::   :CREATE_HUB_SPOKE_CONNECTION
::   :DELETE_HUB_SPOKE_CONNECTION
::   :CallCLI
::   :ShowError
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
call:%*
exit/b
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:LOAD_DEFAULT_DATA
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Modify data about your default hub-and-spoke topology here. 
:: Only modify the values, do not modify the variable names.
::
SET ENVIRONMENT=dev

:: hub vnet data
SET HUB_CIDR=10.0.0.0/16
SET HUB_INTERNAL_CIDR=10.0.0.0/24
SET HUB_GATEWAY_CIDR=10.0.255.224/27
SET HUB_LOCATION=eastus
::
:: spoke vnet SP1 data
SET SP1_CIDR=10.1.0.0/16
SET SP1_INTERNAL_CIDR=10.1.0.0/24
SET SP1_GATEWAY_CIDR=10.1.255.224/27
SET SP1_ILB=10.1.0.254
SET SP1_LOCATION=eastus
::
:: spoke vnet SP2 data
SET SP2_CIDR=10.2.0.0/16
SET SP2_INTERNAL_CIDR=10.2.0.0/24
SET SP2_GATEWAY_CIDR=10.2.255.224/27
SET SP2_ILB=10.2.0.254
SET SP2_LOCATION=eastus
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Global variables
::
:: hub vnet variables
SET HUB_NAME=%RESOURCE_PREFIX%-hub
SET HUB_GATEWAY_NAME=%HUB_NAME%-vgw
SET HUB_GATEWAY_PIP_NAME=%HUB_NAME%-pip
SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg
::
:: on-prem network ONP variables
SET ONP_NAME=%RESOURCE_PREFIX%-onp
SET ONP_GATEWAY_NAME=%ONP_NAME%-vgw
SET ONP_LOCATION=%HUB_LOCATION%
SET ONP_RESOURCE_GROUP=%HUB_RESOURCE_GROUP%
::
:: spoke vnet SP1 variables
SET SP1_NAME=%RESOURCE_PREFIX%-sp1
SET SP1_GATEWAY_NAME=%SP1_NAME%-vgw
SET SP1_GATEWAY_PIP_NAME=%SP1_NAME%-pip
SET SP1_RESOURCE_GROUP=%SP1_NAME%-%ENVIRONMENT%-rg
::
:: spoke vnet SP2 variables
SET SP2_NAME=%RESOURCE_PREFIX%-sp2
SET SP2_GATEWAY_NAME=%SP2_NAME%-vgw
SET SP2_GATEWAY_PIP_NAME=%SP2_NAME%-pip
SET SP2_RESOURCE_GROUP=%SP2_NAME%-%ENVIRONMENT%-rg
::
:: gateway address space CIDR list
:: You need enclose the CIDR list in quotes because they are comma seperated, 
:: If without the quotes, the script subroutine will treat each CIDR as a seperate variable.
::
SET ONP_TO_HUB_CIDR_LIST="%HUB_CIDR%,%SP1_CIDR%,%SP2_CIDR%"
SET SP1_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP2_CIDR%"
SET SP2_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%"

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:CREATE_DEFAULT_VNETS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:CREATE_DEFAULT_VPN_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Create ONP to/from HUB connections
CALL :CREATE_HUB_SPOKE_CONNECTION ^
    %ONP_NAME% ^
    %ONP_CIDR% ^
    %ONP_TO_HUB_CIDR_LIST% ^
    %ONP_GATEWAY_NAME% ^
    %ONP_GATEWAY_PIP% ^
    %ONP_LOCATION% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

:: Create SP1 to/from HUB connections
CALL :CREATE_HUB_SPOKE_CONNECTION ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_TO_HUB_CIDR_LIST% ^
    %SP1_GATEWAY_NAME% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCATION% ^
    %SP1_RESOURCE_GROUP%

:: Create SP2 to/from HUB connections
CALL :CREATE_HUB_SPOKE_CONNECTION ^
    %SP2_NAME% ^
    %SP2_CIDR% ^
    %SP2_TO_HUB_CIDR_LIST% ^
    %SP2_GATEWAY_NAME% ^
    %SP2_GATEWAY_PIP_NAME% ^
    %SP2_LOCATION% ^
    %SP2_RESOURCE_GROUP%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:DELETE_DEFAULT_VPN_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

CALL :DELETE_HUB_SPOKE_CONNECTION ^
    %ONP_NAME% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

CALL :DELETE_HUB_SPOKE_CONNECTION ^
    %SP1_NAME% ^
    %SP1_RESOURCE_GROUP%

CALL :DELETE_HUB_SPOKE_CONNECTION ^
    %SP2_NAME% ^
    %SP2_RESOURCE_GROUP%


GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:CREATE_VNET
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET APP_NAME=%1
SET APP_CIDR=%2
SET APP_INTERNAL_CIDR=%3
SET APP_GATEWAY_CIDR=%4
SET APP_GATEWAY_NAME=%5
SET APP_GATEWAY_PIP_NAME=%6
SET APP_LOCATION=%7
SET APP_RESOURCE_GROUP=%8
SET APP_ILB_FRONTEND_IP_ADDRESS=%9

:: Set up the azure resource names using recommended conventions
SET APP_SUBSCRIPTION=%SUBSCRIPTION%
SET APP_VNET_NAME=%APP_NAME%-vnet

IF "%APP_ILB_FRONTEND_IP_ADDRESS%" == "" (
    ::hub vnet
    SET APP_INTERNAL_SUBNET_NAME=%APP_NAME%-security-subnet
) ELSE (
    ::spoke vnet
    SET APP_INTERNAL_SUBNET_NAME=%APP_NAME%-web-subnet
)

:: Prepare Azure CLI
CALL azure config mode arm

:: Create the resource group
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

:::::::::::::::::::::::::::::::::::::::
:: Create ILB resources
SET APP_ILB_NAME=%APP_NAME%-ilb
SET APP_ILB_FRONTEND_IP_NAME=%APP_NAME%-ilb-fip
SET APP_ILB_POOL_NAME=%APP_NAME%-ilb-pool
SET APP_ILB_PROBE_PROTOCOL=tcp
SET APP_ILB_PROBE_INTERVAL=300
SET APP_ILB_PROBE_COUNT=4
SET APP_ILB_PROBE_NAME=%APP_ILB_NAME%-probe

IF NOT "%APP_ILB_FRONTEND_IP_ADDRESS%" == "" (
  CALL :CallCLI azure network lb create ^
  --name %APP_ILB_NAME% ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

  :: Create a frontend IP address for the internal load balancer
  CALL :CallCLI azure network lb frontend-ip create ^
  --name %APP_ILB_FRONTEND_IP_NAME% ^
  --private-ip-address %APP_ILB_FRONTEND_IP_ADDRESS% ^
  --lb-name %APP_ILB_NAME% ^
  --subnet-name %APP_INTERNAL_SUBNET_NAME% ^
  --subnet-vnet-name %APP_VNET_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

  :: Create the backend address pool for the internal load balancer
  CALL :CallCLI azure network lb address-pool create ^
  --lb-name %APP_ILB_NAME% ^
  --name %APP_ILB_POOL_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

  :: Create a health probe for the internal load balancer
  CALL :CallCLI azure network lb probe create ^
  --name %APP_ILB_PROBE_NAME% ^
  --protocol %APP_ILB_PROBE_PROTOCOL% ^
  --interval %APP_ILB_PROBE_INTERVAL% ^
  --count %APP_ILB_PROBE_COUNT% ^
  --lb-name %APP_ILB_NAME% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%
)
:::::::::::::::::::::::::::::::::::::::
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
  --public-ip-name %APP_GATEWAY_PIP_NAME% ^
  --vnet-name %APP_VNET_NAME% ^
  --location %APP_LOCATION% ^
  --resource-group %APP_RESOURCE_GROUP% ^
  --subscription %APP_SUBSCRIPTION%

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:CREATE_HUB_SPOKE_CONNECTION
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create both local gateways SPK_TO_HUB_LGW and HUB_TO_SPK_LGW
:: and both vpn connections HUB_TO_SPK_VPN-CONNECTION and SPK_TO_HUB_VPN-CONNECTION
:: in SPK_RESOURCE_GROUP so that the spoke resource group is independant of the 
:: hub resource group and spoke resource group can be deleted/modified without touch the 
:: hub resource group

:: input variable
SET SPK_NAME=%1
SET SPK_CIDR=%2
SET SPK_TO_HUB_CIDR_LIST=%3
SET SPK_TO_HUB_CIDR_LIST=%SPK_TO_HUB_CIDR_LIST:~1,-1%
SET SPK_GATEWAY_NAME=%4
SET SPK_GATEWAY_PIP_NAME=%5
SET SPK_LOCATION=%6
SET SPK_RESOURCE_GROUP=%7
SET ON_PREM_FLAG=%8

:: azure resource names
SET HUB_TO_SPK_LGW=%HUB_NAME%-to-%SPK_NAME%-lgw
SET HUB_TO_SPK_VPN-CONNECTION=%HUB_NAME%-to-%SPK_NAME%-vpn-connection

SET SPK_TO_HUB_LGW=%SPK_NAME%-to-%HUB_NAME%-lgw
SET SPK_TO_HUB_VPN-CONNECTION=%SPK_NAME%-to-%HUB_NAME%-vpn-connection

:: Retrieve SPK_GATEWAY_PIP
IF "%ON_PREM_FLAG%" == "on_prem" (
    SET SPK_GATEWAY_PIP=%SPK_GATEWAY_PIP_NAME%
) ELSE (
    :: Parse public-ip json to get the line that contains an ip address.
    :: There is only one line that consists the ip address
    :: Please ignore the message "The system cannot find the drive specified whe you run the script
    FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %SPK_RESOURCE_GROUP% -n %SPK_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

    :: Remove the first 16 and last two charactors to get the ip address
    :: Note the use of ! instead of % since this is inside the IF statement
    SET SPK_GATEWAY_PIP=!JSON_IP_ADDRESS_LINE:~16,-2!
)

:: Retrieve HUB_GATEWAY_PIP
:: Parse public-ip json to get the line that contains an ip address.
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %HUB_RESOURCE_GROUP% -n %HUB_GATEWAY_PIP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON_IP_ADDRESS_LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET HUB_GATEWAY_PIP=%JSON_IP_ADDRESS_LINE:~16,-2%

:: Create HUB_TO_SPK_LGW vpn local gateway
CALL :CallCLI azure network local-gateway create ^
  --name %HUB_TO_SPK_LGW% ^
  --address-space %SPK_CIDR% ^
  --ip-address %SPK_GATEWAY_PIP% ^
  --location %SPK_LOCATION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create SPK_TO_HUB_LGW vpn local gateway
CALL :CallCLI azure network local-gateway create ^
  --name %SPK_TO_HUB_LGW% ^
  --address-space %SPK_TO_HUB_CIDR_LIST% ^
  --ip-address %HUB_GATEWAY_PIP% ^
  --location %SPK_LOCATION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create site-to-site vpn connection HUB_TO_SPK_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection create ^
  --name %HUB_TO_SPK_VPN-CONNECTION% ^
  --vnet-gateway1 %HUB_GATEWAY_NAME% ^
  --vnet-gateway1-group %HUB_RESOURCE_GROUP% ^
  --lnet-gateway2 %HUB_TO_SPK_LGW% ^
  --lnet-gateway2-group %SPK_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %SPK_LOCATION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%

:: Create site-to-site vpn connection SPK_TO_HUB_VPN-CONNECTION
IF NOT "%ON_PREM_FLAG%" == "on_prem" (
  CALL :CallCLI azure network vpn-connection create ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --vnet-gateway1 %SPK_GATEWAY_NAME% ^
  --vnet-gateway1-group %SPK_RESOURCE_GROUP% ^
  --lnet-gateway2 %SPK_TO_HUB_LGW% ^
  --lnet-gateway2-group %SPK_RESOURCE_GROUP% ^
  --type IPsec ^
  --shared-key %IPSEC_SHARED_KEY% ^
  --location %SPK_LOCATION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION%
)
:: ELSE IF "%ON_PREM_FLAG%" == "on_prem", you do not create on-prem to hub 
:: connection in azure. Instead, you need to go to on premise network
:: to route the traffic to the hub gateway pip.

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:DELETE_HUB_SPOKE_CONNECTION
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

::::::::::::::::::::::::::::::::::::::
:: Delete vpn connectrions

:: Delete HUB_TO_SPK_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection delete ^
  --name %HUB_TO_SPK_VPN-CONNECTION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quiet

:: Delete SPK_TO_HUB_VPN-CONNECTION
IF NOT "%ON_PREM_FLAG%" == "on_prem" (
  CALL :CallCLI azure network vpn-connection delete ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quiet

::::::::::::::::::::::::::::::::::::::
:: Delete local gateways

:: Delete HUB_TO_SPK_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %HUB_TO_SPK_LGW% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quiet

:: Delete SPK_TO_HUB_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %SPK_TO_HUB_LGW% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quiet

GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:CallCLI
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
CALL %*
IF ERRORLEVEL 1 (
    CALL :ShowError "Error executing CLI Command: " %*
    :: This executes in the CALLER'S context, so we can exit the whole script on an error
    (GOTO) 2>NULL & GOTO :eof
)
GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTION
:ShowError
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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

