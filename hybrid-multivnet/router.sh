#!/bin/bash
sudo -s
printf 'auto eth1\niface eth1 inet dhcp\n' > /etc/network/interfaces.d/eth1.cfg
printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.conf