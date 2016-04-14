@ECHO OFF

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set up variables.
:: Change these variables to match your deployment.
SET APP_NAME=bc
SET ENVIRONMENT=dev
SET RESOURCE_GROUP=%APP_NAME%-%ENVIRONMENT%-rg

:: Number of Virtual Machines (VMs) to configure. Set according to your scenario.
SET NUM_VMS=3

:: Loop through all the VMs and call subroutine that installs IIS on each VM.
:: Loop counter and the service tier name are passed as parameters.
FOR /L %%I IN (1,1,%NUM_VMS%) DO CALL :ConfigureIIS %%I svc2

GOTO :eof

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Subroutine that configures IIS

:ConfigureIIS
SET TIER_NAME=%2
SET VM_NAME=%APP_NAME%-%TIER_NAME%-vm%1

ECHO Turning on IIS configuration for: %VM_NAME% under resource group: %RESOURCE_GROUP%

:: Following assumes that you have
::  1. Logged into your Azure subscription using "azure login"
::  2. Set the active subscription using "azure account set <subscription-name>"
CALL azure vm extension set --resource-group %RESOURCE_GROUP% --vm-name %VM_NAME% ^
	--name DSC --publisher-name Microsoft.Powershell --version 2.9 ^
	--public-config "{\"commandToExecute\": \" powershell.exe -NoProfile -ExecutionPolicy Unrestricted -File IISConfig.ps1 \"}"
	
	
GOTO :eof
	

