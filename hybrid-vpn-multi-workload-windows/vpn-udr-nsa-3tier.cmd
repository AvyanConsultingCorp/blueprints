@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF "%~5"=="" (
    ECHO Usage: %0 appname subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix
    ECHO   For example: %0 mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24
    EXIT /B
    )
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET APP_NAME=%1
SET SUBSCRIPTION=%2
SET VPN_IPSEC_SHARED_KEY=%3
SET ON_PREMISES_PUBLIC_IP=%4
SET ON_PREMISES_ADDRESS_SPACE=%5
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET LOCATION=centralus
SET ENVIRONMENT=dev
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg
SET POSTFIX=--resource-group %RESOURCE_GROUP% --subscription %SUBSCRIPTION%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET VNET_NAME=%APP_NAME%-vnet
SET VNET_IP_RANGE=10.20.0.0/16
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET VPN_PUBLIC_IP_NAME=%APP_NAME%-pip
SET VPN_LOCAL_GATEWAY_NAME=%APP_NAME%-lgw
SET VPN_CONNECTION_NAME=%APP_NAME%-vpn
SET VPN_GATEWAY_TYPE=RouteBased
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET NAFE_SUBNET_IP_RANGE=10.20.1.0/24
SET NAFE_LOAD_BALANCER_FRONTEND_IP_ADDRESS=10.20.1.254
SET NAFE_SUBNET_NAME=%APP_NAME%-nafe-subnet
SET NAFE_LOAD_BALANCER_NAME=%APP_NAME%-ilb
SET NAFE_LOAD_BALANCER_FRONTEND_IP_NAME=%APP_NAME%-ilb-fip
SET NAFE_LOAD_BALANCER_POOL_NAME=%APP_NAME%-ilb-pool
SET NAFE_LOAD_BALANCER_PROBE_PROTOCOL=tcp
SET NAFE_LOAD_BALANCER_PROBE_INTERVAL=300
SET NAFE_LOAD_BALANCER_PROBE_COUNT=4
SET NAFE_LOAD_BALANCER_PROBE_NAME=%NAFE_LOAD_BALANCER_NAME%-probe
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
CALL azure config mode arm
CALL :CallCLI azure group create --name %RESOURCE_GROUP% --location %LOCATION% --subscription %SUBSCRIPTION%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create vnet
CALL :CallCLI azure network vnet create --address-prefixes %VNET_IP_RANGE% --name %VNET_NAME% --location %LOCATION% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create vpn
CALL :CallCLI azure network vnet subnet create --name GatewaySubnet --vnet-name %VNET_NAME% --address-prefix %GATEWAY_SUBNET_IP_RANGE% %POSTFIX%
CALL :CallCLI azure network public-ip create --name %VPN_PUBLIC_IP_NAME% --allocation-method Dynamic --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network vpn-gateway create --name %VPN_GATEWAY_NAME% --vpn-type %VPN_GATEWAY_TYPE% --public-ip-name %VPN_PUBLIC_IP_NAME% --vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network local-gateway create --name %VPN_LOCAL_GATEWAY_NAME% --address-space %ON_PREMISES_ADDRESS_SPACE% --ip-address %ON_PREMISES_PUBLIC_IP% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network vpn-connection create --name %VPN_CONNECTION_NAME% --vnet-gateway1 %VPN_GATEWAY_NAME% --vnet-gateway1-group %RESOURCE_GROUP% --lnet-gateway2 %VPN_LOCAL_GATEWAY_NAME% --lnet-gateway2-group %RESOURCE_GROUP% --type IPsec --shared-key %VPN_IPSEC_SHARED_KEY% --location %LOCATION% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create nafe subnet
CALL :CallCLI azure network vnet subnet create --name %NAFE_SUBNET_NAME% --vnet-name %VNET_NAME% --address-prefix %NAFE_SUBNET_IP_RANGE% %POSTFIX%
CALL :CallCLI azure network lb create --name %NAFE_LOAD_BALANCER_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network lb frontend-ip create --name %NAFE_LOAD_BALANCER_FRONTEND_IP_NAME% --subnet-vnet-name %VNET_NAME% --subnet-name %NAFE_SUBNET_NAME% --private-ip-address %NAFE_LOAD_BALANCER_FRONTEND_IP_ADDRESS% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
CALL :CallCLI azure network lb address-pool create --name %NAFE_LOAD_BALANCER_POOL_NAME% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
CALL :CallCLI azure network lb probe create --name %NAFE_LOAD_BALANCER_PROBE_NAME% --protocol %NAFE_LOAD_BALANCER_PROBE_PROTOCOL% --interval %NAFE_LOAD_BALANCER_PROBE_INTERVAL% --count %NAFE_LOAD_BALANCER_PROBE_COUNT% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create nabe subnet

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
GOTO :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CallCLI
SETLOCAL
CALL %*
IF ERRORLEVEL 1 (
    CALL :ShowError "Error executing CLI Command: " %*
    REM This command executes in the main script context so we can exit the whole script on an error
    (GOTO) 2>NULL & GOTO :eof
)
GOTO :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ShowError
SETLOCAL EnableDelayedExpansion
REM Print the message
ECHO %~1
SHIFT
REM Get the first part of the azure CLI command so we do not have an extra space at the beginning
SET CLICommand=%~1
SHIFT
REM Loop through the rest of the parameters and recreate the CLI command
:Loop
    IF "%~1"=="" GOTO Continue
    SET "CLICommand=!CLICommand! %~1"
    SHIFT
GOTO Loop
:Continue
ECHO %CLICommand%
GOTO :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
