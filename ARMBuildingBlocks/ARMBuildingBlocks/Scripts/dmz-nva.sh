#!/bin/bash
bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

PRIVATE_IP_ADDRESS=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
PUBLIC_IP_ADDRESS=$(wget http://ipinfo.io/ip -qO -)
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.3.254:80
iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PRIVATE_IP_ADDRESS
iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PUBLIC_IP_ADDRESS
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 10.0.3.254:443
iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 443 -j SNAT --to-source $PRIVATE_IP_ADDRESS
iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 443 -j SNAT --to-source $PUBLIC_IP_ADDRESS
service ufw stop
service ufw start

echo \#\!/bin/bash > /etc/init.d/iptables.sh
echo sudo iptables -F >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -F >> /etc/init.d/iptables.sh
echo sudo iptables -X >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.3.254:80 >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PRIVATE_IP_ADDRESS >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 80 -j SNAT --to-source $PUBLIC_IP_ADDRESS >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 10.0.3.254:443 >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 443 -j SNAT --to-source $PRIVATE_IP_ADDRESS >> /etc/init.d/iptables.sh
echo sudo iptables -t nat -A POSTROUTING -p tcp -d 10.0.3.254 --dport 443 -j SNAT --to-source $PUBLIC_IP_ADDRESS >> /etc/init.d/iptables.sh
echo sudo service ufw stop >> /etc/init.d/iptables.sh
echo sudo service ufw start >> /etc/init.d/iptables.sh

chmod ugo+x /etc/init.d/iptables.sh
update-rc.d iptables.sh defaults
