#!/bin/bash
####################################################
# Note: this script needs to be run as root or with sudo privileges
# pre-requisite: copy public rsa key to raspberryPi
# e.g: scp ~/.ssh/id_rsa.pub pi@raspberry:
####################################################

# SSH Setup

# Parameters
export USERNAME=test
export GROUPS=adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi

# Create new user
useradd -m $USERNAME
usermod -a -G $GROUPS $USERNAME

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

# autologin on system boot
sed -ie "s/pi/$USERNAME/g" /etc/systemd/system/getty.target.wants/getty@tty1.service

## Delete pi user
deluser --remove-all-files pi
reboot
