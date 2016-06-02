#!/bin/bash
sudo bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sudo sysctl -p /etc/sysctl.conf

PRIVATE_IP_ADDRESS=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
PUBLIC_IP_ADDRESS=$(wget http://ipinfo.io/ip -qO -)

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.3.254:80
sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PRIVATE_IP_ADDRESS
sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PUBLIC_IP_ADDRESS
sudo service ufw stop
sudo service ufw start
