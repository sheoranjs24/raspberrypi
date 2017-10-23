#!/usr/bin/bash
####################################################
# run as: sudo ./nfs-setup.sh <rpi_ip> <client_ip>
####################################################

# Parameters
if [[ $# -eq 2 ]];
then
  export RPI_HOSTNAME=$1
  export CLIENT_HOSTNAME=$2
else
  echo "Illegal number of parameters! run as: sudo ./nfs-setup.sh <rpi_ip> <client_ip>"
  exit(1)
fi

##---------------
## Setup NFS
##---------------
apt-get -qq update -y && apt-get -qq dist-upgrade -y && apt-get -qq autoremove -y
apt-get install nfs-kernel-server portmap nfs-common

# Add consumer devices
echo "
# NFS Users
$CLIENT_HOSTNAME jlaptop01" >> /etc/hosts

echo "
/mnt/jsdata1   jlaptop01(rw,insecure,no_subtree_check,sync)
" >> /etc/exports

# Restart the service
service nfs-kernel-server start
#/etc/init.d/nfs-kernel-server restart

# Firewall rules
cp /etc/iptables.firewall.rules /etc/iptables.firewall.rules.bk.`date '+%Y%m%d__%H%M%S'`
sed "s/COMMIT//g" /etc/iptables.firewall.rules
echo "
#  Allow NFS connection from internal network
-A INPUT -s 192.168.0.0/24 -p tcp -m multiport --dport 111,2049 -j ACCEPT
-A INPUT -s 192.168.0.0/24 -p udp -m multiport --dport 111,2049 -j ACCEPT

COMMIT
" >> /etc/iptables.firewall.rules
iptables-restore < /etc/iptables.firewall.rules
iptables -L

## On connecting device:
#mount -t nfs4 -o proto=tcp,port=2049 $RPI_HOSTNAME:/mnt/jsmedia /mnt/jsmedia1
# showmount -a
# df -h
