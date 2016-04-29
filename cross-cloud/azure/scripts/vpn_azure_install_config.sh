#!/bin/bash

# Set "trap" on ERR to be inherited by functions
set -o errtrace

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function
SOURCEFILE=$0
trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "====== ERROR or Interruption, [`date`], ${SOURCEFILE}, line ${1}, exit code ${2}"
  exit ${2}
}

SUDO=''
if [ "$EUID" != "0" ]; then
    SUDO='sudo'
fi

logger()
{
  echo "====== [`date`], ${SOURCEFILE}, $*"
}

usage()
{
  echo
  echo "usage: $0 --aws AWS_PUBLIC_IP --azure AZURE_PUBLIC_IP"
  echo
  echo "    AWS_PUBLIC_IP:  Public IP address of the AWS OpenSwan VM" 
  echo "    AZURE_PUBLIC_IP:  Public IP address of the Azure OpenSwan VM"
  echo 
}

logger "STARTING, command line params [$@]"

AZURE_PUBLICIP=""
AWS_PUBLICIP=""

# Process command-line arguments.
while [ "$1" != "" ]; do
  case $1 in
    --aws )
      shift
      AWS_PUBLICIP="$1"
      ;;
    --azure )
      shift
      AZURE_PUBLICIP="$1"
      ;;
    -h | -? | --help )
      usage
      exit
      ;;
    * )
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "$AZURE_PUBLICIP" == "" ] || [ "$AWS_PUBLICIP" == "" ]; then
  # We need both IP addresses in order to continue.
  echo "ERROR:  Both public IP addresses are needed."
  usage
  exit 1
fi


# Note that we need to call the scripts using bash directly because: 
# 1) the script will not be marked as executable when it is downloaded by 
#    the ARM custom script extension
# 2) bash is needed instead of "sh". "sh" on Ubuntu points to "dash", which 
#    errors on the "trap" with error "trap: sigint: bad trap".

logger "Calling vpn_common.sh"
bash vpn_common.sh

logger "Calling vpn_final_updates.sh"
bash vpn_final_updates.sh --configforazure --aws $AWS_PUBLICIP --azure $AZURE_PUBLICIP 

logger "COMPLETED"
