@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF "%~6"=="" (
    ECHO Usage: %0 appname subscription-id ipsec-shared-key on-prem-gateway-pip on-prem-address-prefix you local box ip prefix
    ECHO   For example: %0 mytest123 13ed86531-1602-4c51-a4d4-afcfc38ddad3 myipsecsharedkey123 11.22.33.44 192.168.0.0/24 13.26.0.0/16
    EXIT /B
    )
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET APP_NAME=%1
SET SUBSCRIPTION=%2
SET VPN_IPSEC_SHARED_KEY=%3
SET ON_PREMISES_PUBLIC_IP=%4
SET ON_PREMISES_ADDRESS_SPACE=%5
SET ADMIN_ADDRESS_PREFIX=%6

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: INPUT
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET USERNAME="testuser"
SET PASSWORD="Passw0rd$1"
SET DIAGNOSTICS_STORAGE=%APP_NAME:-=%diag
SET BOOT_DIAGNOSTICS_STORAGE_URI="https://%DIAGNOSTICS_STORAGE%.blob.core.windows.net/"
SET WINDOWS_BASE_IMAGE=MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:4.0.20160126
SET UBUNDU_BASE_IMAGE=canonical:UbuntuServer:16.04.0-LTS:16.04.201604203

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
SET VPN_GATEWAY_SUBNET_IP_RANGE=10.20.255.224/27
SET VPN_GATEWAY_NAME=%APP_NAME%-vgw
SET VPN_PUBLIC_IP_NAME=%APP_NAME%-pip
SET VPN_LOCAL_GATEWAY_NAME=%APP_NAME%-lgw
SET VPN_LOCAL_GATEWAY_ID=/subscriptions/%SUBSCRIPTION%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Network/localNetworkGateways/%VPN_LOCAL_GATEWAY_NAME%
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
SET NAFE_LOAD_BALANCER_RULE_HTTP=%NAFE_LOAD_BALANCER_NAME%-rule-http-allow
SET NAFE_LOAD_BALANCER_RULE_RDP=%NAFE_LOAD_BALANCER_NAME%-rule-rdp-allow
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET NABE_SUBNET_IP_RANGE=10.20.2.0/24
SET NABE_SUBNET_NAME=%APP_NAME%-nabe-subnet
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET NA_VM_OS_TYPE_Linux=Linux
SET NA_VM_OS_TYPE_Windows=Windows
SET NA_VM_OS_TYPE=%NA_VM_OS_TYPE_Windows%
IF "%NA_VM_OS_TYPE%" == "Windows" (
  SET NA_VM_OS_IMAGE_URN=%WINDOWS_BASE_IMAGE%
) ELSE (
  SET NA_VM_OS_IMAGE_URN=%UBUNDU_BASE_IMAGE%
)
SET NA_VM_SIZE=Standard_A4
SET NA_AVAILSET_NAME=%APP_NAME%-na-as
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET NA_VM1_NAME=%APP_NAME%-na-vm1
SET NA_VM1_OS_DISK_VHD_NAME="%NA_VM1_NAME%-osdisk.vhd"
SET NA_VM1_FE_NIC=%APP_NAME%-na-vm1-fe-nic
SET NA_VM1_BE_NIC=%APP_NAME%-na-vm1-be-nic
SET NA_VM1_FE_NIC_IP=10.20.1.4
SET NA_VM1_BE_NIC_IP=10.20.2.4
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::
SET NA_VM2_NAME=%APP_NAME%-na-vm2
SET NA_VM2_OS_DISK_VHD_NAME="%NA_VM2_NAME%-osdisk.vhd"
SET NA_VM2_FE_NIC=%APP_NAME%-na-vm2-fe-nic
SET NA_VM2_BE_NIC=%APP_NAME%-na-vm2-be-nic
SET NA_VM2_FE_NIC_IP=10.20.1.5
SET NA_VM2_BE_NIC_IP=10.20.2.5
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET WEB_TIER_NAME=web
SET WEB_TIER_AVAILSET_NAME=%APP_NAME%-%TIER_NAME%-as
SET WEB_TIER_SUBNET_IP_RANGE=10.20.3.0/24
SET WEB_TIER_ILB_IP_ADDRESS=10.20.3.254
SET WEB_TIER_NUM_VM_INSTANCES=2
SET WEB_TIER_USING_AVAILSET=true
SET WEB_TIER_LB_NAME=%APP_NAME%-%TIER_NAME%-lb
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET MANAGE_NAME=manage
SET MANAGE_SUBNET_NAME=%MANAGE_NAME%-subnet
SET MANAGE_SUBNET_IP_RANGE=10.20.0.0/24
SET MANAGE_JUMPBOX_VM_NAME=%MANAGE_NAME%-vm1
SET MANAGE_JUMPBOX_VM_NIC_NAME=%MANAGE_JUMPBOX_VM_NAME%-nic1
SET MANAGE_JUMPBOX_VM_NAME_STORAGE=%MANAGE_JUMPBOX_VM_NAME:-=%st1
SET MANAGE_JUMPBOX_VM_SIZE=Standard_DS1
SET MANAGE_JUMPBOX_PUBLIC_IP_NAME=%MANAGE_NAME%-jumpbox-pip
SET MANAGE_NSG_NAME=%MANAGE_NAME%-nsg
SET REMOTE_ACCESS_PORT=3389
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET APP_GATEWAY_UDR=%APP_NAME%-gateway-udr
SET APP_GATEWAY_TO_WEB_RT=%APP_NAME%-gateway-to-web-rt
SET APP_MANAGE_UDR=%APP_NAME%-manage-udr
SET APP_MANAGE_TO_WEB_RT=%APP_NAME%-manage-to-web-rt
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: INPUT END
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::





:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: EXECUTION START ...
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
CALL azure config mode arm
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::GOTO :RESUME
::RESUME
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
CALL :CallCLI azure group create --name %RESOURCE_GROUP% --location %LOCATION% --subscription %SUBSCRIPTION%
:: Create the storage account for diagnostics logs
CALL :CallCLI azure storage account create %DIAGNOSTICS_STORAGE% --type LRS --location %LOCATION% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create vnet
CALL :CallCLI azure network vnet create --name %VNET_NAME% --address-prefixes %VNET_IP_RANGE% --location %LOCATION% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create vpn
CALL :CallCLI azure network vnet subnet create --name GatewaySubnet --vnet-name %VNET_NAME% --address-prefix %VPN_GATEWAY_SUBNET_IP_RANGE% %POSTFIX%
CALL :CallCLI azure network public-ip create --name %VPN_PUBLIC_IP_NAME% --allocation-method Dynamic --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network local-gateway create --name %VPN_LOCAL_GATEWAY_NAME% --address-space %ON_PREMISES_ADDRESS_SPACE% --ip-address %ON_PREMISES_PUBLIC_IP% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network vpn-gateway create --name %VPN_GATEWAY_NAME% --default-site-id %VPN_LOCAL_GATEWAY_ID% --vpn-type %VPN_GATEWAY_TYPE% --sku-name Standard --public-ip-name %VPN_PUBLIC_IP_NAME% --vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network vpn-connection create --name %VPN_CONNECTION_NAME% --vnet-gateway1 %VPN_GATEWAY_NAME% --vnet-gateway1-group %RESOURCE_GROUP% --lnet-gateway2 %VPN_LOCAL_GATEWAY_NAME% --lnet-gateway2-group %RESOURCE_GROUP% --type IPsec --shared-key %VPN_IPSEC_SHARED_KEY% --location %LOCATION% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create na-fe subnet
CALL :CallCLI azure network vnet subnet create --name %NAFE_SUBNET_NAME% --vnet-name %VNET_NAME% --address-prefix %NAFE_SUBNET_IP_RANGE% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create na-fe internal load balancer
CALL :CallCLI azure network lb create --name %NAFE_LOAD_BALANCER_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network lb frontend-ip create --name %NAFE_LOAD_BALANCER_FRONTEND_IP_NAME% --subnet-vnet-name %VNET_NAME% --subnet-name %NAFE_SUBNET_NAME% --private-ip-address %NAFE_LOAD_BALANCER_FRONTEND_IP_ADDRESS% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
CALL :CallCLI azure network lb address-pool create --name %NAFE_LOAD_BALANCER_POOL_NAME% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
CALL :CallCLI azure network lb probe create --name %NAFE_LOAD_BALANCER_PROBE_NAME% --protocol %NAFE_LOAD_BALANCER_PROBE_PROTOCOL% --interval %NAFE_LOAD_BALANCER_PROBE_INTERVAL% --count %NAFE_LOAD_BALANCER_PROBE_COUNT% --lb-name %NAFE_LOAD_BALANCER_NAME% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create na-be subnet
CALL :CallCLI azure network vnet subnet create --name %NABE_SUBNET_NAME% --vnet-name %VNET_NAME% --address-prefix %NABE_SUBNET_IP_RANGE% %POSTFIX%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create na_vm1
CALL :CallCLI azure network nic create --name %NA_VM1_FE_NIC% --subnet-name %NAFE_SUBNET_NAME% --subnet-vnet-name %VNET_NAME% --private-ip-address %NA_VM1_FE_NIC_IP% --enable-ip-forwarding true --location %LOCATION% --resource-group %RESOURCE_GROUP%
CALL :CallCLI azure network nic address-pool create --name %NA_VM1_FE_NIC% --lb-name %NAFE_LOAD_BALANCER_NAME% --lb-address-pool-name %NAFE_LOAD_BALANCER_POOL_NAME% %POSTFIX%
CALL :CallCLI azure network nic create --name %NA_VM1_BE_NIC% --subnet-name %NABE_SUBNET_NAME% --subnet-vnet-name %VNET_NAME% --private-ip-address %NA_VM1_BE_NIC_IP% --enable-ip-forwarding true --location %LOCATION% --resource-group %RESOURCE_GROUP%
CALL :CallCLI azure vm create --name %NA_VM1_NAME% --nic-names %NA_VM1_FE_NIC%,%NA_VM1_BE_NIC% --os-disk-vhd %NA_VM1_OS_DISK_VHD_NAME% --admin-username %USERNAME% --admin-password %PASSWORD% --boot-diagnostics-storage-uri %BOOT_DIAGNOSTICS_STORAGE_URI% --availset-name %NA_AVAILSET_NAME% --os-type %NA_VM_OS_TYPE% --image-urn %NA_VM_OS_IMAGE_URN% --vm-size %NA_VM_SIZE% --vnet-name %VNET_NAME% --location %LOCATION% --resource-group %RESOURCE_GROUP%

:: create na_vm2
CALL :CallCLI azure network nic create --name %NA_VM2_FE_NIC% --subnet-name %NAFE_SUBNET_NAME% --subnet-vnet-name %VNET_NAME% --private-ip-address %NA_VM2_FE_NIC_IP% --enable-ip-forwarding true --location %LOCATION% --resource-group %RESOURCE_GROUP%
CALL :CallCLI azure network nic address-pool create --name %NA_VM2_FE_NIC% --lb-name %NAFE_LOAD_BALANCER_NAME% --lb-address-pool-name %NAFE_LOAD_BALANCER_POOL_NAME% %POSTFIX%
CALL :CallCLI azure network nic create --name %NA_VM2_BE_NIC% --subnet-name %NABE_SUBNET_NAME% --subnet-vnet-name %VNET_NAME% --private-ip-address %NA_VM2_BE_NIC_IP% --enable-ip-forwarding true --location %LOCATION% --resource-group %RESOURCE_GROUP%
CALL :CallCLI azure vm create --name %NA_VM2_NAME% --nic-names %NA_VM2_FE_NIC%,%NA_VM2_BE_NIC% --os-disk-vhd %NA_VM2_OS_DISK_VHD_NAME% --admin-username %USERNAME% --admin-password %PASSWORD% --boot-diagnostics-storage-uri %BOOT_DIAGNOSTICS_STORAGE_URI% --availset-name %NA_AVAILSET_NAME% --os-type %NA_VM_OS_TYPE% --image-urn %NA_VM_OS_IMAGE_URN% --vm-size %NA_VM_SIZE% --vnet-name %VNET_NAME% --location %LOCATION% --resource-group %RESOURCE_GROUP%

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: create na-fe-load balancer rule
CALL :CallCLI azure network lb rule create --name %NAFE_LOAD_BALANCER_RULE_HTTP% --protocol tcp --lb-name %NAFE_LOAD_BALANCER_NAME% --frontend-port 80 --backend-port 80 --frontend-ip-name %NAFE_LOAD_BALANCER_FRONTEND_IP_NAME% --probe-name %NAFE_LOAD_BALANCER_PROBE_NAME% %POSTFIX%
CALL :CallCLI azure network lb rule create --name %NAFE_LOAD_BALANCER_RULE_RDP% --protocol tcp --lb-name %NAFE_LOAD_BALANCER_NAME% --frontend-port %REMOTE_ACCESS_PORT% --backend-port %REMOTE_ACCESS_PORT% --frontend-ip-name %NAFE_LOAD_BALANCER_FRONTEND_IP_NAME% --probe-name %NAFE_LOAD_BALANCER_PROBE_NAME% %POSTFIX%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create the web tier
:: Web tier has a public IP, load balancer, availability set, and two VMs
SET TIER_NAME=%WEB_TIER_NAME%
SET TIER_AVAILSET_NAME=%WEB_TIER_AVAILSET_NAME%
SET TIER_SUBNET_IP_RANGE=%WEB_TIER_SUBNET_IP_RANGE%
SET TIER_ILB_IP_ADDRESS=%WEB_TIER_ILB_IP_ADDRESS%
SET TIER_NUM_VM_INSTANCES=%WEB_TIER_NUM_VM_INSTANCES%
SET TIER_USING_AVAILSET=%WEB_TIER_USING_AVAILSET%
SET TIER_LB_NAME=%WEB_TIER_LB_NAME%
SET TIER_SUBNET_NAME=%APP_NAME%-%TIER_NAME%-subnet

CALL :CallCLI azure network vnet subnet create --vnet-name %VNET_NAME% --address-prefix %TIER_SUBNET_IP_RANGE% --name %TIER_SUBNET_NAME% %POSTFIX%
CALL :CreateLB %TIER_LB_NAME%
CALL :CallCLI azure availset create --name %TIER_AVAILSET_NAME% --location %LOCATION% %POSTFIX%
FOR /L %%I IN (1,1,%TIER_NUM_VM_INSTANCES%) DO CALL :CreateVM %%I %TIER_NAME% %TIER_SUBNET_NAME% %TIER_USING_AVAILSET% %TIER_LB_NAME%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create the management subnet
:: Management subnet has no load balancer, no availability set, and one jump box VM with a public ip address
:: the jump box NSG rule allows inbound remote access traffic from admin-address-prefix script parameter.
SET SUBNET_NAME=%MANAGE_SUBNET_NAME%
SET SUBNET_IP_RANGE=%MANAGE_SUBNET_IP_RANGE%
SET VM_NAME=%MANAGE_JUMPBOX_VM_NAME%
SET NIC_NAME=%MANAGE_JUMPBOX_VM_NIC_NAME%
SET VM_STORAGE=%MANAGE_JUMPBOX_VM_NAME_STORAGE%
SET PUBLIC_IP_NAME=%MANAGE_JUMPBOX_PUBLIC_IP_NAME%
SET VM_SIZE=%MANAGE_JUMPBOX_VM_SIZE%
SET STORAGE_ACCOUNT_NAME=%MANAGE_JUMPBOX_VM_NAME_STORAGE%
SET OS_TYPE=Windows
SET IMAGE_URN=%WINDOWS_BASE_IMAGE%
SET NSG_NAME=%MANAGE_NSG_NAME%

CALL :CallCLI azure network vnet subnet create --name %SUBNET_NAME% --address-prefix %SUBNET_IP_RANGE% --vnet-name %VNET_NAME% %POSTFIX%
CALL :CallCLI azure network nic create --name %NIC_NAME% --subnet-name %SUBNET_NAME% --subnet-vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure storage account create %STORAGE_ACCOUNT_NAME% --type PLRS --location %LOCATION% %POSTFIX%
CALL :CallCLI azure vm create --name %VM_NAME% --os-type %OS_TYPE% --image-urn ^
    %IMAGE_URN% --vm-size %VM_SIZE% --vnet-subnet-name %SUBNET_NAME% ^
    --nic-name %NIC_NAME% --vnet-name %VNET_NAME% --storage-account-name ^
    %STORAGE_ACCOUNT_NAME% --os-disk-vhd "%VM_NAME%-osdisk.vhd" --admin-username ^
    "%USERNAME%" --admin-password "%PASSWORD%" --boot-diagnostics-storage-uri ^
    %BOOT_DIAGNOSTICS_STORAGE_URI% ^
    --location %LOCATION% %POSTFIX%
CALL :CallCLI azure vm disk attach-new --vm-name %VM_NAME% --size-in-gb 128 --vhd-name %VM_NAME%-data1.vhd --storage-account-name %STORAGE_ACCOUNT_NAME% %POSTFIX%
CALL :CallCLI azure network public-ip create --name %PUBLIC_IP_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network nic set --name %NIC_NAME% --public-ip-name %PUBLIC_IP_NAME% %POSTFIX%
CALL :CallCLI azure network nsg create --name %NSG_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network nsg rule create --nsg-name %NSG_NAME% ^
    --name admin-rdp-allow ^
	--access Allow --protocol Tcp --direction Inbound --priority 100 ^
	--source-address-prefix %ADMIN_ADDRESS_PREFIX% --source-port-range * ^
	--destination-address-prefix * --destination-port-range %REMOTE_ACCESS_PORT% %POSTFIX%
CALL :CallCLI azure network nic set --name %NIC_NAME% --network-security-group-name %NSG_NAME% %POSTFIX%

CALL :CreateGatewayUDR
CALL :CreateManageUDR
GOTO :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: EXECUTION END
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::












::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Subroutine to create load balancer resouces: back-end address pool, health probe, and rule
:CreateLB
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET LB_NAME=%1
SET LB_FRONTEND_NAME=%LB_NAME%-frontend
SET LB_BACKEND_NAME=%LB_NAME%-backend-pool
SET LB_PROBE_NAME=%LB_NAME%-probe
SET LB_FRONT_IP_NAME=%LB_NAME%-frontend

CALL :CallCLI azure network lb create --name %TIER_LB_NAME% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network lb frontend-ip create --name %LB_FRONT_IP_NAME% --lb-name %TIER_LB_NAME% --private-ip-address %TIER_ILB_IP_ADDRESS% --subnet-name %TIER_SUBNET_NAME% --subnet-vnet-name %VNET_NAME% %POSTFIX%

CALL :CallCLI azure network lb address-pool create --name %LB_BACKEND_NAME% --lb-name %LB_NAME% %POSTFIX%
CALL :CallCLI azure network lb probe create --name %LB_PROBE_NAME% --lb-name %LB_NAME% --port 80 --interval 5 --count 2 --protocol http --path / %POSTFIX%
CALL :CallCLI azure network lb rule create --name %LB_NAME%-rule-http --protocol tcp --lb-name %LB_NAME% --frontend-port 80 --backend-port 80 --frontend-ip-name %LB_FRONTEND_NAME% --probe-name %LB_PROBE_NAME% %POSTFIX%
GOTO :eof
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Subroutine to create the VMs and per-VM resources
:CreateVM
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET VM_TIER_NAME=%2
SET VM_SUBNET_NAME=%3
SET VM_NEEDS_AVAILABILITY_SET=%4
SET VM_LB_NAME=%5

SET VM_NAME=%APP_NAME%-%VM_TIER_NAME%-vm%1
SET VM_AVAILSET_NAME=%TIER_AVAILSET_NAME%
SET VM_NIC_NAME=%VM_NAME%-nic1
SET VM_VHD_STORAGE=%VM_NAME:-=%st1
SET /a RDP_PORT=50001 + %1
SET VM_SIZE=Standard_DS1

:: Create NIC for VM1
CALL :CallCLI azure network nic create --name %VM_NIC_NAME% --subnet-name %VM_SUBNET_NAME% ^
  --subnet-vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
  
IF NOT "%VM_LB_NAME%"=="" (
	:: Add NIC to back-end address pool
	SET LB_BACKEND_NAME=%VM_LB_NAME%-backend-pool
	CALL :CallCLI azure network nic address-pool create --name %VM_NIC_NAME% ^
    --lb-name %VM_LB_NAME% --lb-address-pool-name %LB_BACKEND_NAME% %POSTFIX%
)

:: Create the storage account for the OS VHD
CALL :CallCLI azure storage account create --type PLRS --location %LOCATION% ^
 %VM_VHD_STORAGE% %POSTFIX%

:: Create the VM
IF "%VM_NEEDS_AVAILABILITY_SET%"=="true" (
  CALL :CallCLI azure vm create --name %VM_NAME% --os-type Windows --image-urn ^
    %WINDOWS_BASE_IMAGE% --vm-size %VM_SIZE% --vnet-subnet-name %VM_SUBNET_NAME% ^
    --nic-name %VM_NIC_NAME% --vnet-name %VNET_NAME% --storage-account-name ^
    %VM_VHD_STORAGE% --os-disk-vhd "%VM_NAME%-osdisk.vhd" --admin-username ^
    "%USERNAME%" --admin-password "%PASSWORD%" --boot-diagnostics-storage-uri ^
    "https://%DIAGNOSTICS_STORAGE%.blob.core.windows.net/" --availset-name ^
    %VM_AVAILSET_NAME% --location %LOCATION% %POSTFIX%
) ELSE (
  CALL :CallCLI azure vm create --name %VM_NAME% --os-type Windows --image-urn ^
    %WINDOWS_BASE_IMAGE% --vm-size %VM_SIZE% --vnet-subnet-name %VM_SUBNET_NAME% ^
    --nic-name %VM_NIC_NAME% --vnet-name %VNET_NAME% --storage-account-name ^
    %VM_VHD_STORAGE% --os-disk-vhd "%VM_NAME%-osdisk.vhd" --admin-username ^
    "%USERNAME%" --admin-password "%PASSWORD%" --boot-diagnostics-storage-uri ^
    "https://%DIAGNOSTICS_STORAGE%.blob.core.windows.net/" ^
    --location %LOCATION% %POSTFIX%
)

:: Attach a data disk
CALL :CallCLI azure vm disk attach-new --vm-name %VM_NAME% --size-in-gb 128 --vhd-name ^
  %VM_NAME%-data1.vhd --storage-account-name %VM_VHD_STORAGE% %POSTFIX%

goto :eof

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
:CreateGatewayUDR
:::::::::::::::::::::::::::::::::::::::
:: Create UDR in gateway subnet
CALL :CallCLI azure network route-table create --name %APP_GATEWAY_UDR% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network route-table route create --name %APP_GATEWAY_TO_WEB_RT% --route-table-name %APP_GATEWAY_UDR% --address-prefix %WEB_TIER_SUBNET_IP_RANGE% --next-hop-type VirtualAppliance --next-hop-ip-address %NAFE_LOAD_BALANCER_FRONTEND_IP_ADDRESS% --resource-group %RESOURCE_GROUP% 
CALL :CallCLI azure network vnet subnet set --name GatewaySubnet --vnet-name %VNET_NAME% --route-table-name %APP_GATEWAY_UDR% --resource-group %RESOURCE_GROUP% 
GOTO :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CreateManageUDR
:::::::::::::::::::::::::::::::::::::::
:: Create UDR in manage subnet
CALL :CallCLI azure network route-table create --name %APP_MANAGE_UDR% --location %LOCATION% %POSTFIX%
CALL :CallCLI azure network route-table route create --name %APP_MANAGE_TO_WEB_RT% --route-table-name %APP_MANAGE_UDR% --address-prefix %WEB_TIER_SUBNET_IP_RANGE% --next-hop-type VirtualAppliance --next-hop-ip-address %NAFE_LOAD_BALANCER_FRONTEND_IP_ADDRESS% --resource-group %RESOURCE_GROUP% 
CALL :CallCLI azure network vnet subnet set --name %MANAGE_SUBNET_NAME% --vnet-name %VNET_NAME% --route-table-name %APP_MANAGE_UDR% --resource-group %RESOURCE_GROUP% 
GOTO :eof
