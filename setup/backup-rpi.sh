##--------------------
## Automated backups
##--------------------
# Daily automated backup of SD Card
mkdir -p -m 755 /mnt/jsmedia1/backup/rasbian
cp scripts/backup_rasbian.sh /mnt/jsmedia1/backup/backup_rasbian.sh
chmod 754 /mnt/jsmedia1/backup/backup_rasbian.sh

echo "0 22 * * * root bash /mnt/jsmedia1/backup/backup_rasbian.sh >> /var/log/cron/cron.rasbian.log 2>&1 \n" > /etc/cron.d/backup-rasbian
