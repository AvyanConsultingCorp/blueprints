::@ECHO OFF
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
SET DEPLOYMENT_NAME=%APP_NAME%-%ENVIRONMENT%-deployment-%RANDOM%
CALL azure config mode arm

:: create network 
SET RESOURCE_GROUP=%APP_NAME%-ntwk-rg
SET vnet6subnetsTemplate=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-vnet-6subnets.json
CALL azure group create --name %RESOURCE_GROUP% --location %LOCATION% --subscription %SUBSCRIPTION%
CALL azure group deployment create --template-uri %vnet6subnetsTemplate% -g %RESOURCE_GROUP% -e azuredeploy.param.json 
::CALL azure group deployment create -f azuredeploy.json -e azuredeploy.param.json -g %RESOURCE_GROUP%

:: create web vms and ILB
SET RESOURCE_GROUP=%APP_NAME%-sn-web-rg
SET webTemplate=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
CALL azure group create --name %RESOURCE_GROUP% --location %LOCATION% --subscription %SUBSCRIPTION%
CALL azure group deployment create --template-uri %webTemplate% -g %RESOURCE_GROUP% -e azuredeploy.param.json 
s
GOTO :eof
