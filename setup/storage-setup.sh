#!/bin/bash
####################################################
# run as: sudo ./storage-setup.sh <username> <groupname> <drive1> <drive2>
# device names can be retrieved by running: fdisk -l
# pre-requisite: ?
####################################################

export USERNAME=$1
export GROUPNAME=$2
export DRIVE1=$3
export DRIVE2=$4

## Install Dependencies
apt-get -qq update
apt-get -qq upgrade -y
apt-get -qq install -y hfsplus hfsutils hfsprogs  # HFS+ support
apt-get -qq install -y ntfs-3g                    # NTFS support
apt-get -qq install -y exfat-utils                # exFAT support
apt-get -qq install -y rsync
reboot

## Format Drive
# parted
#	  print all
#	  select $DRIVE1
#	  print
#   mklabel gpt       #format HDD with GPT partition table
#   print
#   mkpart primary ext4  0GB 100%  #ex4 partition
#   print.
#   q
# mkfs.ext4 /dev/sda1

## Create Mounts
export DRIVE1_UUID=`blkid -o value -s UUID $DRIVE1`
mkdir /mnt/media1
mount -t ext4 $DRIVE1 /mnt/media1
chown -R $USERNAME:$GROUPNAME /mnt/media1
chmod -R 750 /mnt/media1
chmod -R g+s /mnt/media1
echo "UUID=$DRIVE1_UUID\t/mnt/media1\text4\tauto,noatime,nofail\t0\t2" >> /etc/fstab

export DRIVE2_UUID=`blkid -o value -s UUID $DRIVE2`
mkdir /mnt/media2
mount -t ext4 $DRIVE2 /mnt/media2
chown -R $USERNAME:$GROUPNAME /mnt/media2
chmod -R 750 /mnt/media2
chmod -R g+s /mnt/media2
echo "UUID=$DRIVE2_UUID\t/mnt/media2\text4\tauto,noatime,nofail\t0\t2" >> /etc/fstab

## Daily automated backup of SD Card
mkdir -p /mnt/media1/backups/rasbian
echo '#!/bin/bash

# backup memory card
dd bs=4M if=/dev/mmcblk0 | gzip > /mnt/media1/backups/rasbian/rasbian.$(date +%F).img.gz

# delete backups older than 7 days
find /mnt/media1/backups/rasbian/rasbian.*.img.gz -mtime +7 -exec rm {} \;' >> /mnt/media1/backups/rasbian/backup_rasbian.sh

echo "0 22 * * * * root bash /mnt/media1/backups/rasbian/backup_rasbian.sh" > /etc/cron.d/backup-rasbian

## Daily automated rsync of media drive
mkdir -p /mnt/media1/backups/media
echo '#!/bin/bash
# backup drive
rsync -av --delete /mnt/media1 /mnt/media2 >> /var/log/rsync.$(date +%F).log' >> /mnt/media1/backups/media/backup_media.sh

echo "0 23 * * * * root bash /mnt/media1/backups/media/backup_media.sh" > /etc/cron.d/backup-media
