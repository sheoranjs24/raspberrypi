#!/usr/bin/bash
####################################################
# run as: sudo ./samba-setup.sh <username> <password> <cidr>
####################################################

# Parameters
if [[ $# -eq 3 ]];
then
  export USERNAME=$1
  export PASSWORD=$2
  export CIDR=$3
else
  echo "Illegal number of parameters! run as: sudo ./samba-setup.sh <username> <password> <cidr>
  e.g. ./samba-setup.sh user pass 192.168.0.0/24"
  exit(1)
fi

##---------------
## Setup SAMBA
##---------------
apt-get -qq update -y && apt-get -qq dist-upgrade -y && apt-get -qq autoremove -y
apt-get -qq install -y  samba samba-common-bin

# Create samba config
cp /etc/samba/smb.conf /etc/samba/smb.conf.bk
grep -ve ^\# -ve ‘^;’ -ve ^$ /etc/samba/smb.conf > /etc/samba/smb.conf
echo "
# My shared directories
[jsmedia1]
    comment = Media HDD 1
    path = /mnt/jsmedia1
    valid users = @users
    force group = users
    create mask = 0640
    directory mask = 0750
    public = no
    only guest = no
    guest ok = no
    available = yes
    browsable = yes
    read only = no
    writable = yes
" >> /etc/samba/smb.conf

# Create samba users
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -s -a $USERNAME

# List samba users
pdbedit -L

# Restart the service
service samba restart
#/etc/init.d/samba restart

# Firewall rules
cp /etc/iptables.firewall.rules /etc/iptables.firewall.rules.bk.`date '+%Y%m%d__%H%M%S'`
sed "s/COMMIT//g" /etc/iptables.firewall.rules
echo "
#  Allow Samba connection from internal network
-A INPUT -s $CIDR -p tcp -m tcp --dport 137 -j ACCEPT
-A INPUT -s $CIDR -p tcp -m tcp --dport 138 -j ACCEPT
-A INPUT -s $CIDR -p tcp -m tcp --dport 139 -j ACCEPT
-A INPUT -s $CIDR -p tcp -m tcp --dport 445 -j ACCEPT

COMMIT
" >> /etc/iptables.firewall.rules
iptables-restore < /etc/iptables.firewall.rules
iptables -L
