:: add-spoke.cmd
::
@ECHO OFF
SETLOCAL EnableDelayedExpansion
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This script will add new spoke the the default hub-spoke topology. 

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
:: modify the new spoke data here
SET SP_NEW_NAME=%RESOURCE_PREFIX%-mynewsp
SET SP_NEW_CIDR=10.3.0.0/16
SET SP_NEW_INTERNAL_CIDR=10.3.0.0/24
SET SP_NEW_GATEWAY_CIDR=10.3.255.224/27
SET SP_NEW_ILB=10.3.0.254
SET SP_NEW_LOCATION=eastus

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: load data and subroutines
::
CALL load-data-default.cmd

:: Subroutines in load-subroutine-base.cmd
::   :CREATE_VNET
::   :CREATE_HUB_SPOKE_CONNECTION
::   :DELETE_HUB_SPOKE_CONNECTION
::   :CallCLI
::   :ShowError
CALL load-subroutine-base.cmd

:: Subroutines in load-subroutine-default.cmd
::   :CREATE_DEFAULT_VNETS
::   :CREATE_DEFAULT_VPN_CONNECTIONS
::   :DELETE_DEFAULT_VPN_CONNECTIONS
CALL load-subroutine-default.cmd

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: re-create default vpn connections

CALL :DELETE_DEFAULT_VPN_CONNECTIONS

:: Modify existing gateway address space CIDR list by adding
:: ,%SP_NEW_CIDR% 
SET ONP_TO_HUB_CIDR_LIST="%HUB_CIDR%,%SP1_CIDR%,%SP2_CIDR%,%SP_NEW_CIDR%"
SET SP1_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP2_CIDR%,%SP_NEW_CIDR%"
SET SP2_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP_NEW_CIDR%"

:: re-create default vpn connectins use
:: updated CIDR list 
CALL :CREATE_DEFAULT_VPN_CONNECTIONS

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: new spoke vnet variables
SET SP_NEW_GATEWAY_NAME=%SP2_NAME%-vgw
SET SP_NEW_GATEWAY_PIP_NAME=%SP2_NAME%-pip
SET SP_NEW_RESOURCE_GROUP=%SP2_NAME%-%ENVIRONMENT%-rg
SET SP_NEW_TO_HUB_CIDR_LIST="%HUB_CIDR%,%ONP_CIDR%,%SP1_CIDR%,%SP2_CIDR%"

:: create new spoke vnet
CALL :CREATE_VNET ^
    %SP_NEW_NAME% ^
    %SP_NEW_CIDR% ^
    %SP_NEW_INTERNAL_CIDR% ^
    %SP_NEW_GATEWAY_CIDR% ^
    %SP_NEW_GATEWAY_NAME% ^
    %SP_NEW_GATEWAY_PIP_NAME% ^
    %SP_NEW_LOCATION% ^
    %SP_NEW_RESOURCE_GROUP% ^
    %SP_NEW_ILB%

:: connect new spoke vnet to the hub
CALL :CREATE_HUB_SPOKE_CONNECTION ^
    %SP_NEW_NAME% ^
    %SP_NEW_CIDR% ^
    %SP_NEW_TO_HUB_CIDR_LIST% ^
    %SP_NEW_GATEWAY_NAME% ^
    %SP_NEW_GATEWAY_PIP_NAME% ^
    %SP_NEW_LOCATION% ^
    %SP_NEW_RESOURCE_GROUP%

GOTO :eof
