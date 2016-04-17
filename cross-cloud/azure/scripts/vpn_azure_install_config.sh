#!/bin/bash

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

if [ $# -ne 2  ]
then
	echo  "Usage:  ${0} AWS_PUBLIC_IP AZURE_PUBLIC_IP"
	exit
fi

echo "****** Calling vpn_common.sh"
bash vpn_common.sh

echo "****** Calling vpn_final_updates.sh"
bash vpn_final_updates.sh --configforazure --aws $1 --azure $2 
