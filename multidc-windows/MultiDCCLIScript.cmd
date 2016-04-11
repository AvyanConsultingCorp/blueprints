::@ECHO OFF
SETLOCAL

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set up variables for deploying resources to Azure.
:: Change these variables for your own deployment

:: The APP_NAME variable must not exceed 4 characters in size.
:: If it does the 15 character size limitation of the VM name may be exceeded.
SET APP_NAME=app2
SET PRIMARY_LOCATION=centralus
SET SECONDARY_LOCATION=eastus
SET ENVIRONMENT=dev
SET USERNAME=testuser

:: For Windows, use the following command to get the list of URNs:
:: azure vm image list %LOCATION% MicrosoftWindowsServer WindowsServer 2012-R2-Datacenter
SET WINDOWS_BASE_IMAGE=MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:4.0.20160126

:: For a list of VM sizes see: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/
:: To see the VM sizes available in a region:
:: 	azure vm sizes --location <<location>>
SET VM_SIZE=Standard_DS1

SET TRAFFICMANAGERPROFILE_MONITORPATH=/healthprobe/index/123

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

IF "%3"=="" (
    ECHO Usage: %0 subscription-id admin-address-whitelist-CIDR-format admin-password
    ECHO   For example: %0 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx nnn.nnn.nnn.nnn/mm pwd
    EXIT /B
    )

:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default

SET SUBSCRIPTION=%1
SET ADMIN_ADDRESS_PREFIX=%2
SET PASSWORD=%3

:: Set up the names of things using recommended conventions
SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg
SET TRAFFICMANAGERPROFILE_NAME=%APP_NAME%-%ENVIRONMENT%-tm
SET TRAFFICMANAGERPROFILE_DNSNAME=%APP_NAME%%ENVIRONMENT%

SET PRIMARYPUBLIC_IP_NAME=%APP_NAME%-primary-pip
SET SECONDARYPUBLIC_IP_NAME=%APP_NAME%-secondary-pip
SET DIAGNOSTICS_STORAGE=%APP_NAME:-=%diag

:: Set up the postfix variables attached to most CLI commands
SET POSTFIX=--resource-group %RESOURCE_GROUP% --subscription %SUBSCRIPTION%

CALL azure config mode arm


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create root level resources

:: Create the enclosing resource group
CALL azure group create --name %RESOURCE_GROUP% --location %PRIMARY_LOCATION% ^
  --subscription %SUBSCRIPTION%

:: Create the public IP address (dynamic)
CALL azure network public-ip create --name %PRIMARYPUBLIC_IP_NAME% ^
  --location %PRIMARY_LOCATION% --domain-name-label %PRIMARYPUBLIC_IP_NAME% %POSTFIX%

:: Create the failover public IP address (dynamic)
CALL azure network public-ip create --name %SECONDARYPUBLIC_IP_NAME% ^
  --location %SECONDARY_LOCATION% --domain-name-label %SECONDARYPUBLIC_IP_NAME% %POSTFIX%

CALL azure network traffic-manager profile create ^
  --name %TRAFFICMANAGERPROFILE_NAME% ^
  --relative-dns-name %TRAFFICMANAGERPROFILE_DNSNAME% ^
  --monitor-path %TRAFFICMANAGERPROFILE_MONITORPATH% ^
  --traffic-routing-method Priority  %POSTFIX%

SET PRIMARY_PUBLIC_IP_RESOURCEID=/subscriptions/%SUBSCRIPTION%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Network/publicIPAddresses/%PRIMARYPUBLIC_IP_NAME%
SET SECONDARY_PUBLIC_IP_RESOURCEID=/subscriptions/%SUBSCRIPTION%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Network/publicIPAddresses/%SECONDARYPUBLIC_IP_NAME%

CALL azure network traffic-manager endpoint create ^
  --name %TRAFFICMANAGERPROFILE_NAME%-ep-primary ^
  --profile-name %TRAFFICMANAGERPROFILE_NAME% ^
  --type AzureEndpoints ^
  --target-resource-id %PRIMARY_PUBLIC_IP_RESOURCEID% ^
  --priority 1 %POSTFIX%

CALL azure network traffic-manager endpoint create ^
  --name %TRAFFICMANAGERPROFILE_NAME%-ep-secondary ^
  --profile-name %TRAFFICMANAGERPROFILE_NAME% ^
  --type AzureEndpoints ^
  --target-resource-id %SECONDARY_PUBLIC_IP_RESOURCEID% ^
  --priority 100 %POSTFIX%
