:: createtopology.cmd
:: create default hub-and-spoke topology
::
@ECHO OFF
SETLOCAL EnableDelayedExpansion

:: This script will create or modify a hub-spoke topology. 
:: By default it will have one on-prem network, one hub, and two spokes.
::
IF "%~5"=="" (
    ECHO Usage: %0 resource-group-prefix subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix
    ECHO   For example: %0 mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24
    EXIT /B
    )

:: input variables from the command line
SET RESOURCE_PREFIX=%1
SET SUBSCRIPTION=%2
SET IPSEC_SHARED_KEY=%3
SET ONP_GATEWAY_PIP=%4
SET ONP_CIDR=%5

CALL load-data.cmd

CALL function.cmd :CREATE_DEFAULT_VNETS

CALL function.cmd :CREATE_DEFAULT_VPN_CONNECTIONS

GOTO :eof

