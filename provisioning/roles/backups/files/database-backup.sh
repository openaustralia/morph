#!/bin/sh

# Backup the database to /backups/mysql and keep the last five days around
# This script should be run from a cron job once a day.

count_backups() {
  backup_count="$(ls -1 $BACKUP_DIR | wc -l)"
}

find_oldest_backup() {
  oldest_backup="$BACKUP_DIR/$(ls -1rt $BACKUP_DIR | head -n 1)"
}

perform_backup() {
  innobackupex --compress $BACKUP_DIR --user=root
}

setup_backup() {
  mkdir -p $BACKUP_DIR
  # Created files should just readable (and writeable) by root
  umask 077
}

# Free up all available disk space before a backup happens.
free_all_available_disk_space() {
  docker system prune --all --force
}

set -e
BACKUP_DIR="/backups/mysql"
MAX_BACKUPS=1

setup_backup
free_all_available_disk_space
perform_backup
count_backups

while [ $backup_count -gt $MAX_BACKUPS ]; do
  find_oldest_backup
  rm -rf $oldest_backup
  count_backups
done
