#!/bin/bash

# This script will configure the OpenSwan VM config files /etc/ipsec.conf and
# /etc/ipsec.secrets for either AWS or Azure.
# This assumes the following:
#   AWS:    subnet is 192.168.0.0/16, OpenSwan local IP is 192.168.0.4
#   Azure:  subnet is 10.0.0.0/16, OpenSwan local IP is 10.0.0.4
# Command-line parameters determine if you are configuring the AWS or Azure
# side and what the public IP addresses are for the AWS and Azure OpenSwan VMs

SOURCEFILE=$0

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function
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
    echo "usage: $0 <--configforazure | --configforaws> --aws AWS_PUBLIC_IP --azure AZURE_PUBLIC_IP"
    echo
}

logger "STARTING, command line params [$@]"

AZURE_PUBLICIP=""
AWS_PUBLICIP=""
CONFIGAZURE=""
CONFIGAWS=""
CONFIG=""
LEFT=""
LEFTSUBNET=""
RIGHT=""

# If no command-line arguements, just print the usage and exit.
if [ "$1" == "" ]; then
    usage
	exit 1
fi

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
        --configforazure )
            CONFIGAZURE="1"
            CONFIG="AZURE"
            ;;
        --configforaws )
            CONFIGAWS="1"
            CONFIG="AWS"
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

if [ "$CONFIGAWS" != "" ] && [ "$CONFIGAZURE" != "" ]; then
    # We need one or the other set, but not both
	echo "ERROR:  Cannot use both AWS and AZURE config options."
	usage
	exit 1
fi

if [ "$CONFIG" == "" ]; then
	# We need one config option chosen...either we're configuring for Azure or AWS
	echo "ERROR:  One config option must be chosen"
	usage
	exit 1
fi

###### Main

echo "Configuring for $CONFIG"
echo "Using AWS Public IP = $AWS_PUBLICIP, Azure Public IP = $AZURE_PUBLICIP"
echo

if [ "$CONFIG" == "AWS" ]; then
	LEFT="192.168.0.4"
	LEFTSUBNET="192.168.0.0/16"
	RIGHTSUBNET="10.0.0.0/16"
	LEFTID="$AWS_PUBLICIP"
	RIGHT="$AZURE_PUBLICIP"
elif [ "$CONFIG" == "AZURE" ]; then
	LEFT="10.0.0.4"
	LEFTSUBNET="10.0.0.0/16"
	RIGHTSUBNET="192.168.0.0/16"
	LEFTID="$AZURE_PUBLICIP"
	RIGHT="$AWS_PUBLICIP"
fi

# Add a connection to ipsec.conf
echo "Appending the following to /etc/ipsec.conf:"
echo "
      force_keepalive=yes
      keep_alive=60
      nhelpers=0

conn aws_azure_vpn
    left=${LEFT}
    leftsubnet=${LEFTSUBNET}
    leftid=${LEFTID}
    right=${RIGHT}
    rightsubnet=${RIGHTSUBNET}
    pfs=no
    forceencaps=yes
    authby=secret
    auto=start
" | $SUDO tee -a /etc/ipsec.conf

# Add a shared secret to ipsec.secrets
echo "Appending the following to /etc/ipsec.secrets:"
echo "${AZURE_PUBLICIP} ${AWS_PUBLICIP} : PSK \"thelongsharedsupersecretkey\"
" | $SUDO tee -a /etc/ipsec.secrets

# Restart the IPsec service for the changes to take affect
$SUDO service ipsec restart

logger "COMPLETED"
