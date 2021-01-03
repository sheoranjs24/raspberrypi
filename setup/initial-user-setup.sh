#!/usr/bin/bash
####################################################
# run as: sudo ./new-user-setup.sh <username>
####################################################

# Parameters
if [[ $# -eq 1 ]];
then
  export USERNAME=$1
else
  echo "Illegal number of parameters! run as: sudo ./new-user-setup.sh <username>"
  exit(1)
fi

# Create new user
export GROUPS=adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi
useradd -m $USERNAME
usermod -a -G $GROUPS $USERNAME

## SSH Config
mkdir /home/$USERNAME/.ssh
cp /home/pi/.ssh/id_rsa.pub /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
sed -i "s/^ChallengeResponseAuthentication.*$/ChallengeResponseAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*$/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*$/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/^UsePAM.*$/UsePAM no/g" /etc/ssh/sshd_config
sed -i "s/^AllowUsers.*$/AllowUsers $USERNAME/g" /etc/ssh/sshd_config

# autologin on system boot
sed -ie "s/pi/$USERNAME/g" /etc/systemd/system/getty.target.wants/getty@tty1.service

# Reboot the system
reboot
