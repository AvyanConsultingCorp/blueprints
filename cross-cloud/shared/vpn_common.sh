#!/bin/bash
# Install Openswan on the VPN server

SOURCEFILE=$0

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function
trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "====== ERROR or Interruption, [`date`], ${SOURCEFILE}, line ${1}, exit code ${2}"
  exit ${2}
}

logger()
{
  echo "====== [`date`], ${SOURCEFILE}, $*"
}

logger "STARTING"

# Wait for cloud-init to finish building the server
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

# Update the package library
sudo apt-get -y update
sudo apt-get -y install debconf-utils iperf

# Install Openswan in noninteractive mode
echo 'openswan openswan/install_x509_certificate select false
      openswan openswan/restart select true
      openswan openswan/runlevel_changes note
      openswan openswan/x509_self_signed select false' | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get --yes --force-yes install openswan

# Enable ip forwarding
echo "Appending the following to /etc/sysctl.conf:"
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Make changes take affect
sudo sysctl -p /etc/sysctl.conf

logger "COMPLETED"
