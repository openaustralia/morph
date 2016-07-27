#!/bin/sh

# Backup the database to /backups/mysql and keep the last seven days around
# This script should be run from a cron job once per days

BACKUP_DIR="/backups/mysql"
mkdir -p $BACKUP_DIR
# Created files should just readable (and writeable) by root
umask 077 

/usr/bin/innobackupex --compress $BACKUP_DIR --user=root

no_backups=`ls -1 $BACKUP_DIR | wc -l`
while [ $no_backups -gt 7 ]
do
  oldest=`ls -1rt $BACKUP_DIR | head -n 1`
  rm -rf $BACKUP_DIR/$oldest
  no_backups=`ls -1 $BACKUP_DIR | wc -l`
done
