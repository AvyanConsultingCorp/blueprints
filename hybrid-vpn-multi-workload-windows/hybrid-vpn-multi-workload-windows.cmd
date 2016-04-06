

@ECHO OFF
SETLOCAL

IF "%~1"=="" (
    ECHO Usage: %0 subscription-id
    ECHO   For example: %0 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    EXIT /B
    )

:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default
SET SUBSCRIPTION=%1

:: Set global avariables that is common to all virtual networks
SET ENVIRONMENT=dev
SET VPN_GATEWAY_TYPE=RouteBased

:: Create hub and spoke vnets.
:: If you don't specify ilb_fe_ip, the internal load balancer will not 
:: be created, which could be suited for the hub vnet.
::
::::::CREATE_VNET name vnet_addrss  gateway_addrss subnt_adrss  loc   ilb_fe_ip
CALL :CREATE_VNET App0 10.0.0.0/16 10.0.255.240/28 10.0.0.0/17 eastus 
CALL :CREATE_VNET App1 10.1.0.0/16 10.1.255.240/28 10.1.0.0/17 eastus 10.1.127.254 
CALL :CREATE_VNET App2 10.2.0.0/16 10.2.255.240/28 10.2.0.0/17 eastus 10.2.127.254 
CALL :CREATE_VNET App3 10.3.0.0/16 10.3.255.240/28 10.3.0.0/17 eastus 10.3.127.254 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CREATE_VNET
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF "%~6"=="" (
    ECHO Usage: %0 app vnet_ip_range gateway_ip_range internal_subnet_ip_range location is_hub ilb_fe_ip
    ECHO   For example: %0 App1 10.1.0.0/16 10.1.255.240/28 10.1.0.0/17 eastus false 10.1.127.254
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
SET LOCAL_GATEWAY_NAME=%APP_NAME%-lgw
SET VPN_CONNECTION_NAME=%APP_NAME%-vpn

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

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create resources

:: Create the enclosing resource group
CALL :CallCLI azure group create --name %RESOURCE_GROUP% --location %LOCATION% ^
  --subscription %SUBSCRIPTION%

:: Create the VNet
CALL :CallCLI azure network vnet create --address-prefixes %VNET_IP_RANGE% ^
  --name %VNET_NAME% --location %LOCATION% %POSTFIX%

:: Create the GatewaySubnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %GATEWAY_SUBNET_IP_RANGE% --name GatewaySubnet %POSTFIX%

:: Create public IP address for VPN Gateway
:: Note that the Azure VPN Gateway only supports dynamic IP addresses
CALL :CallCLI azure network public-ip create --allocation-method Dynamic ^
  --name %PUBLIC_IP_NAME% --location %LOCATION% %POSTFIX%

:: Create virtual network gateway
CALL :CallCLI azure network vpn-gateway create --name %VPN_GATEWAY_NAME% ^
  --type %VPN_GATEWAY_TYPE% --public-ip-name %PUBLIC_IP_NAME% --vnet-name %VNET_NAME% ^
  --location %LOCATION% %POSTFIX

:: Parse public-ip json to get the line that contains an ip address. 
:: There is only one line that consists the ip address
FOR /F "delims=" %%a in ('
    CALL azure network public-ip show -g %RESOURCE_GROUP% -n %PUBLIC_IP_NAME% --json ^| 
    FINDSTR /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
    ') DO @SET JSON-IP-ADDRESS-LINE=%%a

:: Remove the first 16 and last two charactors to get the ip address
SET VPN-GATEWAY-PIP-ADDRESS=%JSON-IP-ADDRESS-LINE:~16,-2%

:: Create local gateway
CALL :CallCLI azure network local-gateway create --name %LOCAL_GATEWAY_NAME% ^
  --address-space %VNET_IP_RANGE% --ip-address %VPN-GATEWAY-PIP-ADDRESS% ^
  --location %LOCATION% %POSTFIX%

:: Create a site-to-site connection
CALL :CallCLI azure network vpn-connection create --name %VPN_CONNECTION_NAME% ^
  --vnet-gateway1 %VPN_GATEWAY_NAME% --vnet-gateway1-group %RESOURCE_GROUP% ^
  --lnet-gateway2 %LOCAL_GATEWAY_NAME% --lnet-gateway2-group %RESOURCE_GROUP% ^
  --type IPsec --location %LOCATION% %POSTFIX%

:: Create the internal subnet
CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% ^
  --address-prefix %INTERNAL_SUBNET_IP_RANGE% --name %INTERNAL_SUBNET_NAME% %POSTFIX%

IF %INTERNAL_LOAD_BALANCER_FRONTEND_IP_ADDRESS% == "" (
GOTO :eof
)

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

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CallCLI
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL
CALL %*
IF ERRORLEVEL 1 (
    CALL :ShowError "Error executing CLI Command: " %*
    :: This executes in the CALLER'S context, so we can exit the whole script on an error
    (GOTO) 2>NULL & GOTO :eof
)
GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ShowError
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

