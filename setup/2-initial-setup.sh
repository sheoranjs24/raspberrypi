#!/bin/bash
####################################################
# run as: sudo ./2-initial-setup.sh <username>
# pre-requisite: copy public rsa key to raspberryPi
# e.g: scp ~/.ssh/id_rsa.pub pi@raspberry:
####################################################

# SSH Setup

# Parameters
export USERNAME=$1
export GROUPS=adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi

# Create new user
useradd -m $USERNAME
usermod -a -G $GROUPS $USERNAME

# autologin on system boot
sed -ie "s/pi/$USERNAME/g" /etc/systemd/system/getty.target.wants/getty@tty1.service

## Delete pi user
deluser --remove-all-files pi

## Fixed IP
touch /etc/network/interfaces
echo "
auto eth0
iface eth0 inet static
       address 192.168.1.101
       gateway 192.168.1.1
       netmask 255.255.255.0
       network 192.168.1.0
       broadcast 192.168.1.255
" >> /etc/network/interfaces
/etc/init.d/networking restart 

## SSH Config
mkdir /home/$USERNAME/.ssh
mv id_rsa.pub /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
sed -i "s/^PasswordAuthentication.*$/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*$/PermitRootLogin no/g" /etc/ssh/sshd_config
service ssh restart

## Create a Firewall
iptables -L
echo "
*filter

#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT

#  Accept all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#  Allow all outbound traffic - you can modify this to only allow certain traffic
-A OUTPUT -j ACCEPT

#  Allow HTTPS connections from anywhere (the normal port for SSL)
-A INPUT -p tcp --dport 443 -j ACCEPT

#  Allow SSH connections
#  The -dport number should be the same port number you set in sshd_config
-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT

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
apt-get -qq update
apt-get -qq install -y fail2ban  # logs at /var/log/fail2ban.log

# Reboot the system
reboot
