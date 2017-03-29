#!/bin/bash
# Setup new user

export USERNAME=test
export GROUPS=adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi

sudo useradd -m $USERNAME
sudo passwd $USERNAME
sudo usermod -a -G $GROUPS $USERNAME

# autologin on system boot
sudo sed -ie "s/pi/$USERNAME/g" /etc/systemd/system/getty.target.wants/getty@tty1.service

sudo reboot
