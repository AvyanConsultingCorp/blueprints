@ECHO OFF
SETLOCAL EnableDelayedExpansion

:: This script will delete vpn connections and local gateways setup in 
:: hybrid-vpn-multi-workload-winodws.cmd which consists a hub-spoke topology 
:: with one on-prem network, one hub, and three spokes.

IF "%~2" == "" (
    ECHO Usage: %0 subscription-id resource-group-prefix 
    ECHO   For example: %0 13ed86531-1602-4c51-a4d4-afcfc38ddad3 mytest123
    EXIT /B
    )

:: input variables from the command line
SET SUBSCRIPTION=%1
SET RESOURCE_PREFIX=%2

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Global variables
::
:: hub vnet variables
SET HUB_NAME=%RESOURCE_PREFIX%-hub
SET HUB_RESOURCE_GROUP=%HUB_NAME%-%ENVIRONMENT%-rg
::
:: on-prem network ONP variables
SET ONP_NAME=%RESOURCE_PREFIX%-onp
SET ONP_RESOURCE_GROUP=%HUB_RESOURCE_GROUP%
::
:: spoke vnet SP1 variables
SET SP1_NAME=%RESOURCE_PREFIX%-sp1
SET SP1_RESOURCE_GROUP=%SP1_NAME%-%ENVIRONMENT%-rg
::
:: spoke vnet SP2 variables
SET SP2_NAME=%RESOURCE_PREFIX%-sp2
SET SP2_RESOURCE_GROUP=%SP2_NAME%-%ENVIRONMENT%-rg
::

:: Delete all existing vpn connections

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
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: SUBROUTINE
::DELETE_SPOKE_TO_HUB_AND_HUB_TO_SPOKE_CONNECTIONS_AND_LOCAL_GATEWAYS
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

:: Delete HUB_TO_SPK_VPN-CONNECTION
CALL :CallCLI azure network vpn-connection delete ^
  --name %HUB_TO_SPK_VPN-CONNECTION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

:: Delete SPK_TO_HUB_VPN-CONNECTION
IF NOT "%ON_PREM_FLAG%" == "on_prem" (
  CALL :CallCLI azure network vpn-connection delete ^
  --name %SPK_TO_HUB_VPN-CONNECTION% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

:: Delete HUB_TO_SPK_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %HUB_TO_SPK_LGW% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

:: Delete SPK_TO_HUB_LGW
CALL :CallCLI azure network local-gateway delete ^
  --name %SPK_TO_HUB_LGW% ^
  --resource-group %SPK_RESOURCE_GROUP% ^
  --subscription %SUBSCRIPTION% ^
  --quite

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
