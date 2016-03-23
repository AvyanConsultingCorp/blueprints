#!/bin/bash

# Install PostgreSQL and the client

# Wait for cloud-init to finish building the server
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'

# Update the package library
sudo apt-get -y update

# Install postgresql version 9.3.x
echo "Installing PostgreSQL version 9.3.x"
sudo apt-get -y install debconf-utils postgresql=9.3* postgresql-contrib=9.3* postgresql-client=9.3*
