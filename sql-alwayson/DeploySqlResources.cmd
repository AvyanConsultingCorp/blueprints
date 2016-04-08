ECHO ON
SETLOCAL 

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set up variables for deploying resources to Azure.
:: Change these variables for your own deployment.

SET STORAGE_PREFIX=mikew

:: The APP_NAME variable must not exceed 4 characters in size.
:: If it does the 15 character size limitation of the VM name may be exceeded.
SET APP_NAME=dc02
SET USERNAME=sqladmin

SET LOCATION=westus

:: For Windows, use the following command to get the list of URNs:
:: azure vm image list %LOCATION% MicrosoftWindowsServer WindowsServer 2012-R2-Datacenter
SET WINDOWS_BASE_IMAGE=MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:4.0.20160126

:: For SQL Server, use the following command to get the list of URNs:
:: azure vm image list westus MicrosoftSQLServer SQL2014SP1-WS2012R2 Enterprise
SET SQLSEVER_IMAGE=MicrosoftSQLServer:SQL2014SP1-WS2012R2:Enterprise:12.0.4100


:: For a list of VM sizes see: 
::   https://azure.microsoft.com/documentation/articles/virtual-machines-size-specs/
:: To see the VM sizes available in a region:
:: 	azure vm sizes --location <location>
SET VM_SIZE=Standard_DS2

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

IF "%~2"=="" (
    ECHO Usage: %0 subscription-id admin-password
    EXIT /B
    )

:: Explicitly set the subscription to avoid confusion as to which subscription
:: is active/default
SET SUBSCRIPTION=%1
SET PASSWORD=%2


CALL azure config mode arm


:: Build DC-1

SET RESOURCE_GROUP=%APP_NAME%-rg
SET VNET_NAME=%APP_NAME%-vnet
SET DIAGNOSTICS_STORAGE=%STORAGE_PREFIX%%APP_NAME:-=%diag

:: Set up the postfix variables attached to most CLI commands
SET POSTFIX=--resource-group %RESOURCE_GROUP% --subscription %SUBSCRIPTION%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create resources

:: Create the enclosing resource group
CALL azure group create --name %RESOURCE_GROUP% --location %LOCATION% ^
  --subscription %SUBSCRIPTION%

:: Create the VNet
CALL azure network vnet create --address-prefixes 10.0.0.0/16 ^
  --name %VNET_NAME% --dns-servers "10.0.0.4,10.0.0.6" --location %LOCATION% %POSTFIX%

:: Create the subnets
CALL azure network vnet subnet create --vnet-name %VNET_NAME% --address-prefix ^
   10.0.0.0/24 --name ad-subnet %POSTFIX%

CALL azure network vnet subnet create --vnet-name %VNET_NAME% --address-prefix ^
   10.0.1.0/24 --name sql-subnet %POSTFIX%

CALL azure network vnet subnet create --vnet-name %VNET_NAME% --address-prefix ^
  10.0.2.0/24 --name jumpbox-subnet %POSTFIX%

REM CALL azure network vnet subnet create --vnet-name %VNET_NAME% --address-prefix ^
REM   10.0.3.0/24 --name GatewaySubnet %POSTFIX%

:: Create the storage account for diagnostics logs
CALL azure storage account create --type LRS --location %LOCATION% %POSTFIX% ^
  %DIAGNOSTICS_STORAGE%
  
  
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create VMs and per-VM resources

:: Domain controller VMs
SET ROLE=ad
SET AVAILSET_NAME=%APP_NAME%-%ROLE%-as

:: Create the availability set
CALL azure availset create --name %AVAILSET_NAME% --location %LOCATION% %POSTFIX%

:: Create AD domain controller VMs with static private IPs
CALL :CreateVmPrivateIp %APP_NAME%-%ROLE%-1 %AVAILSET_NAME% ad-subnet %WINDOWS_BASE_IMAGE% 10.0.0.4 
CALL :CreateVmPrivateIp %APP_NAME%-%ROLE%-2 %AVAILSET_NAME% ad-subnet %WINDOWS_BASE_IMAGE% 10.0.0.6

:: SQL VMs
SET ROLE=sql
SET AVAILSET_NAME=%APP_NAME%-%ROLE%-as
CALL azure availset create --name %AVAILSET_NAME% --location %LOCATION% %POSTFIX%

:: Create with dynamic private IP
CALL :CreateVmPrivateIp %APP_NAME%-%ROLE%-1 %AVAILSET_NAME% sql-subnet %SQLSEVER_IMAGE%
CALL :CreateVmPrivateIp %APP_NAME%-%ROLE%-2 %AVAILSET_NAME% sql-subnet %SQLSEVER_IMAGE%

:: File share watcher
SET ROLE=fsw
CALL :CreateVmPrivateIp %APP_NAME%-%ROLE% %AVAILSET_NAME% sql-subnet %WINDOWS_BASE_IMAGE%

:: Jumpbox VM
SET ROLE=jump
SET AVAILSET_NAME=%APP_NAME%-%ROLE%-as
CALL azure availset create --name %AVAILSET_NAME% --location %LOCATION% %POSTFIX%

:: Create with public IP address
CALL :CreateVmPublicIp %APP_NAME%-%ROLE% %AVAILSET_NAME% jumpbox-subnet %WINDOWS_BASE_IMAGE%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create NSG for jumpbox

SET NSG_NAME=%APP_NAME%-jumpbox-nsg

:: Create the network security group
CALL azure network nsg create --name %NSG_NAME% --location %LOCATION% %POSTFIX%

CALL azure network nsg rule create --nsg-name %NSG_NAME% --direction Inbound ^
  --protocol Tcp --destination-port-range 3389 --source-port-range * ^
  --priority 100 --access Allow --name RDPAllow %POSTFIX%

:: Associate the NSG rule with the jumpbox subnet
CALL azure network vnet subnet set --vnet-name %VNET_NAME% --name jumpbox-subnet ^
  --network-security-group-name %NSG_NAME% %POSTFIX%


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Load balancer

SET LB_NAME=sql-lb
SET LB_FRONTEND_NAME=%LB_NAME%-frontend
SET LB_BACKEND_NAME=%LB_NAME%-backend-pool
SET LB_PROBE_NAME=%LB_NAME%-probe

:: Create the load balancer
CALL azure network lb create --name %LB_NAME% --location %LOCATION% %POSTFIX%

:: Create LB front-end with a static IP address
CALL azure network lb frontend-ip create --name %LB_FRONTEND_NAME% --lb-name ^
  %LB_NAME% --private-ip-address 10.0.1.7 --subnet-name sql-subnet ^
  --subnet-vnet-name %VNET_NAME% %POSTFIX%

:: Create LB back-end address pool
CALL azure network lb address-pool create --name %LB_BACKEND_NAME% --lb-name ^
  %LB_NAME% %POSTFIX%

:: Create a health probe for an HTTP endpoint
CALL azure network lb probe create --name %LB_PROBE_NAME% --lb-name %LB_NAME% ^
  --port 59999 --interval 5 --count 2 --protocol tcp %POSTFIX%

:: Create a load balancer rule for HTTP
CALL azure network lb rule create --name %LB_NAME%-rule-http --protocol tcp ^
  --lb-name %LB_NAME% --frontend-port 1433 --backend-port 1433 --frontend-ip-name ^
  %LB_FRONTEND_NAME% --probe-name %LB_PROBE_NAME% %POSTFIX%


GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create a VM with a public IP
:CreateVmPublicIp

SET VM_NAME=%1%
SET AVAILSET_NAME=%2%
SET SUBNET_NAME=%3%
SET OS_IMAGE=%4%

SET NIC_NAME=%VM_NAME%-nic1
SET PIP_NAME=%VM_NAME%-pip

:: Create NIC
CALL azure network nic create --name %NIC_NAME% --subnet-name %SUBNET_NAME% ^
  --subnet-vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%

:: Create the public IP address (dynamic)
CALL azure network public-ip create --name %PIP_NAME% --location %LOCATION% %POSTFIX%

:: Set public IP on the NIC
CALL azure network nic set --name %NIC_NAME% --public-ip-name %PIP_NAME% %POSTFIX%

CALL :CreateVm %VM_NAME% %AVAILSET_NAME% %SUBNET_NAME% %NIC_NAME% %OS_IMAGE%

GOTO :eof


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Create a VM with a private IP
:CreateVmPrivateIp

SET VM_NAME=%1%
SET AVAILSET_NAME=%2%
SET SUBNET_NAME=%3%
SET OS_IMAGE=%4%
:: STATIC_IP is empty for dynamic IP address 
SET STATIC_IP=%5%

SET NIC_NAME=%VM_NAME%-nic1

:: Create NIC
:: Use static IP address if specified
IF "%STATIC_IP%"=="" (
    CALL azure network nic create --name %NIC_NAME% --subnet-name %SUBNET_NAME% ^
    --subnet-vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
) ELSE (
    CALL azure network nic create --name %NIC_NAME% --subnet-name %SUBNET_NAME% ^
    --private-ip-address %STATIC_IP% --subnet-vnet-name %VNET_NAME% --location %LOCATION% %POSTFIX%
)

CALL :CreateVm %VM_NAME% %AVAILSET_NAME% %SUBNET_NAME% %NIC_NAME% %OS_IMAGE%

GOTO :eof
 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Subroutine to create the VMs and per-VM resources

:CreateVm

ECHO Creating VM %1

SET VM_NAME=%1%
SET AVAILSET_NAME=%2%
SET SUBNET_NAME=%3%
SET NIC_NAME=%4%
SET OS_IMAGE=%5%

SET VHD_STORAGE=%STORAGE_PREFIX%%VM_NAME:-=%st1

:: Create the storage account for the OS VHD
CALL azure storage account create --type PLRS --location %LOCATION% ^
 %VHD_STORAGE% %POSTFIX%

:: Create the VM
CALL azure vm create --name %VM_NAME% --os-type Windows --image-urn ^
  %OS_IMAGE% --vm-size %VM_SIZE% --vnet-subnet-name %SUBNET_NAME% ^
  --nic-name %NIC_NAME% --vnet-name %VNET_NAME% --storage-account-name ^
  %VHD_STORAGE% --os-disk-vhd "%VM_NAME%-osdisk.vhd" --admin-username ^
  "%USERNAME%" --admin-password "%PASSWORD%" --boot-diagnostics-storage-uri ^
  "https://%DIAGNOSTICS_STORAGE%.blob.core.windows.net/" --availset-name ^
  %AVAILSET_NAME% --location %LOCATION% %POSTFIX%

:: Attach a data disk
CALL azure vm disk attach-new --vm-name %VM_NAME% --size-in-gb 128 --vhd-name ^
  %VM_NAME%-data1.vhd --storage-account-name %VHD_STORAGE% %POSTFIX%

goto :eof
