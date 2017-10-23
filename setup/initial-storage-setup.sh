#!/bin/bash
####################################################
# run as: sudo ./storage-setup.sh <username> [<drive1> <drive2>]
# device names can be retrieved by running: fdisk -l
# pre-requisite: format drives to ext4
####################################################

## Parameters
if [[ ($# -eq 1 || $# -eq 3) ]];
then
  export USERNAME=$1
  if [[ $# -eq 3 ]];
  then
    export DRIVE1=$2
    export DRIVE2=$3
  else
    export DRIVE1=/dev/sda
    export DRIVE2=/dev/sdb
  fi
else
  echo "Illegal number of parameters! run as:  sudo ./storage-setup.sh <username> [<drive1> <drive2>]"
  exit(1)
fi

##-----------------
## Format Drive
##-----------------
echo Do you wish to format the primary storage disk (y/n)?
read input1
if [[ $input1 == "y" ]]; then
  parted --script $DRIVE1 \
      mklabel gpt \
      mkpart primary ext4 0GB 100%
fi
parted --script $DRIVE1 print

echo Do you wish to format the secondary storage disk (y/n)?
read input2
if [[ $input1 == "y" ]]; then
  parted --script $DRIVE2 \
      mklabel gpt \
      mkpart primary ext4 0GB 100%
fi
parted --script $DRIVE2 print
# mkfs.ext4 /dev/sda1

##--------------------
## Install Dependencies
##--------------------
apt-get -qq update -y && apt-get -qq dist-upgrade -y && apt-get -qq autoremove -y
apt-get -qq install -y hfsplus hfsutils hfsprogs  # HFS+ support
apt-get -qq install -y ntfs-3g                    # NTFS support
apt-get -qq install -y exfat-utils                # exFAT support
apt-get -qq install -y rsync

##--------------------
## Create Mounts
##--------------------
export GROUPNAME=users
export DRIVE1_UUID=`blkid -o value -s UUID $DRIVE1`
mkdir /mnt/jsmedia1
mount -t ext4 $DRIVE1 /mnt/jsmedia1
chown -R $USERNAME:$GROUPNAME /mnt/jsmedia1
chmod -R 750 /mnt/jsmedia1
chmod -R g+s /mnt/jsmedia1
echo "UUID=$DRIVE1_UUID\t/mnt/jsmedia1\text4\trw,auto,noatime,nofail\t0\t2" >> /etc/fstab

export DRIVE2_UUID=`blkid -o value -s UUID $DRIVE2`
mkdir /mnt/jsmedia2
mount -t ext4 $DRIVE2 /mnt/jsmedia2
chown -R $USERNAME:$GROUPNAME /mnt/jsmedia2
chmod -R 750 /mnt/jsmedia2
chmod -R g+s /mnt/jsmedia2
echo "UUID=$DRIVE2_UUID\t/mnt/jsmedia2\text4\trw,auto,noatime,nofail\t0\t2" >> /etc/fstab

##--------------------
## Automated backups
##--------------------
# Daily automated backup of SD Card
mkdir -p -m 755 /mnt/jsmedia1/backup/rasbian
echo '#!/bin/bash

# backup memory card
dd bs=4M if=/dev/mmcblk0 | gzip > /mnt/jsmedia1/backup/rasbian/rasbian.$(date +%F).img.gz

# delete backups older than 7 days
find /mnt/jsmedia1/backup/rasbian/rasbian.*.img.gz -mtime +7 -exec rm {} \;' >> /mnt/jsmedia1/backup/rasbian/backup_rasbian.sh

chmod 754 /mnt/jsmedia1/backup/rasbian/backup_rasbian.sh
echo "0 22 * * * root bash /mnt/jsmedia1/backup/rasbian/backup_rasbian.sh >> /var/log/cron/cron.rasbian.log 2>&1 \n" > /etc/cron.d/backup-rasbian

# Daily automated rsync of media drive
mkdir -p /mnt/jsmedia1/backup/jsmedia
echo "#!/bin/bash
# backup drive
rsync -av --delete /mnt/jsmedia1 /mnt/jsmedia2 >> /var/log/rsync/rsync.jsmedia.$(date +%F).log 2>&1" >> /mnt/jsmedia1/backup/jsmedia/backup_jsmedia.sh

chmod 754 /mnt/jsmedia1/backup/jsmedia/backup_jsmedia.sh
echo "0 0 * * * root bash /mnt/jsmedia1/backup/jsmedia/backup_jsmedia.sh >> /var/log/cron/cron.jsmedia.log 2>&1 \n" > /etc/cron.d/backup-jsmedia

##--------------------
## Reboot
##--------------------
reboot
