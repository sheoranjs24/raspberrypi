##--------------------
## Automated backups
##--------------------
# Daily automated rsync of media drive
mkdir -p /mnt/jsmedia1/backup/jsmedia
echo '#!/bin/bash
# backup drive
rsync -av --delete /mnt/jsmedia1 /mnt/jsmedia2 >> /var/log/rsync/rsync.jsmedia.$(date +%F).log 2>&1' > /mnt/jsmedia1/backup/backup_jsmedia.sh

chmod 754 /mnt/jsmedia1/backup/backup_jsmedia.sh
echo "0 0 * * * root bash /mnt/jsmedia1/backup/backup_jsmedia.sh >> /var/log/cron/cron.jsmedia.log 2>&1 \n" > /etc/cron.d/backup-jsmedia
