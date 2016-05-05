@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF "%~5"=="" (
    ECHO Usage: %0 appname subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix
    ECHO   For example: %0 mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24
    EXIT /B
    )
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Command Arguments
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET APP_NAME=%1
SET SUBSCRIPTION=%2
SET VPN_IPSEC_SHARED_KEY=%3
SET ON_PREMISES_PUBLIC_IP=%4
SET ON_PREMISES_ADDRESS_SPACE=%5


SET LOCATION=centralus
SET ENVIRONMENT=dev
SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg
SET DEPLOYMENT_NAME=%APP_NAME%-%ENVIRONMENT%-deployment
CALL azure config mode arm

CALL azure group create --name %RESOURCE_GROUP% --location %LOCATION% --subscription %SUBSCRIPTION%

CALL azure group template validate -f azuredeploy.json -g %RESOURCE_GROUP%

CALL azure group deployment create -f azuredeploy.json -e azuredeploy.param.json -g %RESOURCE_GROUP% -n %DEPLOYMENT_NAME%

GOTO :eof
