#!/bin/bash
####################################################
# run as: sudo ./storage-setup.sh <username> <drive> <mount>
# example: sudo ./storage-setup.sh sheoran /dev/sda /mnt/media
# device names can be retrieved by running: fdisk -l
# pre-requisite: format drives to ext4
####################################################

## Parameters
if [[ $# -eq 3 ]];
then
  export USERNAME=$1
  export DRIVE=$2
  export DIRECTORY=$3  
else
  echo "Illegal number of parameters! run as:  sudo ./storage-setup.sh <username> <drive> <mount>"
  exit(1)
fi

##----------------
## List Devices
##----------------
sudo lsblk -o UUID,NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,MODEL

##--------------------
## Install Dependencies
##--------------------
apt-get -qq update -y && apt-get -qq dist-upgrade -y && apt-get -qq autoremove -y
apt-get -qq install -y hfsplus hfsutils hfsprogs  # HFS+ support
apt-get -qq install -y ntfs-3g                    # NTFS support
apt-get -qq install -y exfat-utils                # exFAT support
apt-get -qq install -y rsync

##-----------------
## Format Drive
##-----------------
echo "Do you wish to format the primary storage disk (y/n)?"
read input1
if [[ $input1 == "y" ]]; then
  parted --script $DRIVE \
      mklabel gpt \
      mkpart primary ext4 0GB 100%
fi
parted --script $DRIVE print
# mkfs.ext4 /dev/sda1

##--------------------
## Create Mounts
##--------------------
export GROUPNAME=users
export DRIVE_UUID=`blkid -o value -s UUID $DRIVE`
mkdir /mnt/$DIRECTORY
mount -t ext4 $DRIVE /mnt/DIRECTORY
chown -R $USERNAME:$GROUPNAME /mnt/$DIRECTORY
chmod -R 750 /mnt/$DIRECTORY
chmod -R g+s /mnt/$DIRECTORY
echo "UUID=$DRIVE_UUID\t/mnt/$DIRECTORY\text4\trw,auto,noatime,nofail\t0\t2" >> /etc/fstab

##--------------------
## Reboot
##--------------------
reboot
