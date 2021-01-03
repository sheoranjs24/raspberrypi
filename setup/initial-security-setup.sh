#!/usr/bin/bash
####################################################
# run as: sudo ./initial-security-setup.sh <networkIP> [<raspberryPiHostIp>]
####################################################

# Parameters
if [[ $# -eq 1 ]];
then
  export NETWORK_IP=$1
  export RPI_HOSTNAME=192.168.1.101  #todo: FIXME
elif [[ $# -eq 2 ]];
export NETWORK_IP=$1
export RPI_HOSTNAME=$2
else
  echo "Illegal number of parameters! run as: sudo ./initial-security-setup.sh <networkIP> [<raspberryPiHostIp>]"
  exit(1)
fi

##-----------------
## Delete pi user
##-----------------
deluser --remove-all-files pi


##-----------------
## Monitoring
##-----------------
mkdir /var/log/apt /var/log/auth /var/log/cron /var/log/daemon /var/log/kern /var/log/mail /var/log/rsync
sudo chown root:adm /var/log/apt /var/log/auth /var/log/cron /var/log/daemon /var/log/kern /var/log/mail /var/log/rsync
## update rsyslog conf
cp /etc/rsyslog.conf /etc/rsyslog.conf.bk
sed -ie "s/auth,authpriv.*                 \/var\/log\/auth.log/auth,authpriv.*                 \/var\/log\/auth\/auth.log\nauthpriv.*                      \/var\/log\/auth\/auth.log/g" /etc/rsyslog.conf
sed -ie "s/#cron.*                         \/var\/log\/cron.log/cron.*                          \/var\/log\/cron\/cron.log/g" /etc/rsyslog.conf
sed -ie "s/daemon.*                        -\/var\/log\/daemon.log/daemon.*                        -\/var\/log\/daemon\/daemon.log/g" /etc/rsyslog.conf
sed -ie "s/kern.*                          -\/var\/log\/kern.log/kern.*                          -\/var\/log\/kern\/kern.log/g" /etc/rsyslog.conf
sed -ie "s/lpr.*                           -\/var\/log\/lpr.log/lpr.*                           -\/var\/log\/lpr\/lpr.log/g" /etc/rsyslog.conf
sed -ie "s/mail.*                          -\/var\/log\/mail.log/mail.*                          -\/var\/log\/mail\/mail.log/g" /etc/rsyslog.conf
sed -ie "s/user.*                          -\/var\/log\/user.log/user.*                          -\/var\/log\/user\/user.log/g" /etc/rsyslog.conf
sed -ie "s/mail.info                       -\/var\/log\/mail.info/mail.info                       -\/var\/log\/mail\/mail.info/g" /etc/rsyslog.conf
sed -ie "s/mail.warn                       -\/var\/log\/mail.warn/mail.warn                       -\/var\/log\/mail\/mail.warn/g" /etc/rsyslog.conf
sed -ie "s/mail.err                        \/var\/log\/mail.err/mail.err                        \/var\/log\/mail\/mail.err/g" /etc/rsyslog.conf


##-----------------
## Fixed IP
##-----------------
touch /etc/network/interfaces
echo "
auto eth0
iface eth0 inet static
       address $RPI_HOSTNAME
       gateway 192.168.1.1
       netmask 255.255.255.0
       network 192.168.1.0
       broadcast 192.168.1.255
" >> /etc/network/interfaces


##-----------------
## Create a Firewall
##-----------------
iptables -L
echo "
*filter

#  Allow all outbound traffic
-A OUTPUT -j ACCEPT

#  Accept all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT

#  Allow SSH connections
-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT

#  Allow HTTP & HTTPS connections from anywhere
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT

#  Log iptables denied calls
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

#  Drop all other inbound - default deny unless explicitly allowed policy
-A INPUT -j DROP
-A FORWARD -j DROP

COMMIT
" >> /etc/iptables.firewall.rules
iptables-restore < /etc/iptables.firewall.rules
iptables -L
echo "
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.firewall.rules" >> /etc/network/if-pre-up.d/firewall
chmod +x /etc/network/if-pre-up.d/firewall


##-----------------
## Security
##-----------------
# Update the package list, update all packages and remove any packages that are no longer required
apt-get -qq update -y && apt-get -qq dist-upgrade -y && apt-get -qq autoremove -y
apt install openssh-server
apt-get -qq install -y fail2ban  # logs at /var/log/fail2ban.log
mkdir /var/log/fail2ban
sudo chown root:adm /var/log/fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.conf.bk
cp /etc/fail2ban/jail.conf  /etc/fail2ban/jail.conf.bk
sed -ie "s/logtarget = \/var\/log\/fail2ban.log/logtarget = \/var\/log\/fail2ban\/fail2ban.log/g" /etc/fail2ban/fail2ban.conf
sed -ie "s/logpath  = \/var\/log\/auth.log/logpath  = \/var\/log\/auth\/auth.log/g" /etc/fail2ban/jail.conf


##-----------------
# Reboot the system
##-----------------
reboot
