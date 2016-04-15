:: reset-default-topology.cmd
:: This script will reset the topology to default 
:: Steps that lead to this script:
::    step1: create-default-topology.cmd
::    step2: do something to change the topology connnections, but don't delete vent or vpn gateways
::    step3: reset-default-topology.cmd
@ECHO OFF
SETLOCAL EnableDelayedExpansion

IF "%~5"=="" (
    ECHO Usage: %0 resource-group-prefix subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix
    ECHO   For example: 
    ECHO   %0 mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24
    ECHO   The first two parameters resource-group-prefix and subscription-id 
    ECHO   must be the same as that you used when creating the original topology
    EXIT /B
    )

:: input variables from the command line
SET RESOURCE_PREFIX=%1
SET SUBSCRIPTION=%2
SET IPSEC_SHARED_KEY=%3
SET ONP_GATEWAY_PIP=%4
SET ONP_CIDR=%5

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: load data for default hub-spoke topology
CALL pnp-hub-spoke-functions.cmd :LOAD_DEFAULT_DATA

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: delete the existing default vpn connections
CALL pnp-hub-spoke-functions.cmd :DELETE_DEFAULT_VPN_CONNECTIONS

:: re-create default vpn connections with modified CIDR
CALL pnp-hub-spoke-functions.cmd :CREATE_DEFAULT_VPN_CONNECTIONS

GOTO :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
