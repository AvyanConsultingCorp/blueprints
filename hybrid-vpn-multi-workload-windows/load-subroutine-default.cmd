:: load-subroutine-default.cmd
:: Subroutines in this file:
::   :CREATE_DEFAULT_VNETS
::   :CREATE_DEFAULT_VPN_CONNECTIONS
::   :DELETE_DEFAULT_VPN_CONNECTIONS

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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
:CREATE_DEFAULT_VPN_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Create ONP_TO_HUB_TO_ONP connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %ONP_NAME% ^
    %ONP_CIDR% ^
    %ONP_TO_HUB_CIDR_LIST% ^
    %ONP_GATEWAY_NAME% ^
    %ONP_GATEWAY_PIP% ^
    %ONP_LOCATION% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

:: Create SP1_TO_HUB_TO_SP1 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_TO_HUB_CIDR_LIST% ^
    %SP1_GATEWAY_NAME% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCATION% ^
    %SP1_RESOURCE_GROUP%

:: Create SP2_TO_HUB_TO_SP2 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP2_NAME% ^
    %SP2_CIDR% ^
    %SP2_TO_HUB_CIDR_LIST% ^
    %SP2_GATEWAY_NAME% ^
    %SP2_GATEWAY_PIP_NAME% ^
    %SP2_LOCATION% ^
    %SP2_RESOURCE_GROUP%

:: Create ONP_TO_HUB_TO_ONP connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %ONP_NAME% ^
    %ONP_CIDR% ^
    %ONP_TO_HUB_CIDR_LIST% ^
    %ONP_GATEWAY_NAME% ^
    %ONP_GATEWAY_PIP% ^
    %ONP_LOCATION% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

:: Create SP1_TO_HUB_TO_SP1 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
    %SP1_NAME% ^
    %SP1_CIDR% ^
    %SP1_TO_HUB_CIDR_LIST% ^
    %SP1_GATEWAY_NAME% ^
    %SP1_GATEWAY_PIP_NAME% ^
    %SP1_LOCATION% ^
    %SP1_RESOURCE_GROUP%

:: Create SP2_TO_HUB_TO_SP2 connections
CALL :CREATE_SPOKE_TO_AND_FROM_HUB_CONNECTION ^
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
:DELETE_DEFAULT_VPN_CONNECTIONS
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS_AND_LOCAL_GATEWAYS ^
    %ONP_NAME% ^
    %ONP_RESOURCE_GROUP% ^
    on_prem

CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS_AND_LOCAL_GATEWAYS ^
    %SP1_NAME% ^
    %SP1_RESOURCE_GROUP%

CALL ::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS_AND_LOCAL_GATEWAYS ^
    %SP2_NAME% ^
    %SP2_RESOURCE_GROUP%


GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::