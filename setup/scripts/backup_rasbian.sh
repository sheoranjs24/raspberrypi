#!/bin/bash

# backup memory card
dd bs=4M if=/dev/mmcblk0 | gzip > /mnt/jsmedia1/backup/rasbian/rasbian.$(date +%F).img.gz

# delete backups older than 7 days
find /mnt/jsmedia1/backup/rasbian/rasbian.*.img.gz -mtime +7 -exec rm {} \;

# run system update
sudo apt-get update -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y
