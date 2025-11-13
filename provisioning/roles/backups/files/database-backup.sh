#!/bin/bash

# Backup all databases to /backups/mysql with timestamps
# Run as root from cron daily

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

BACKUP_DIR="${BACKUP_DIR:-/backups/mysql}"
mkdir -p "$BACKUP_DIR"
umask 077
# bash only option: Check mysqldump as well as zstd in pipe for failure
set -o pipefail

OPTIONS="--add-drop-table --single-transaction --no-tablespaces"

# Skip system databases
SKIP_DATABASES="^(Database|mysql|sys|information_schema|performance_schema)$"

# Get list of databases
DATABASES=$(mysql --user=root -e "SHOW DATABASES;" | grep -v -E "$SKIP_DATABASES")

exit_status=0
# Loop through each database
for DB_NAME in $DATABASES; do
    BACKUP_NAME="$DB_NAME.$TIMESTAMP.sql.zst"
    echo "Dumping database: $DB_NAME to $BACKUP_NAME"

    # compress inline so we need only about 5% not 50% of the disk available
    # shellcheck disable=SC2086
    if mysqldump --user=root $OPTIONS "$DB_NAME" | zstd -T0 -9 > "$BACKUP_DIR/$BACKUP_NAME.tmp"; then
        mv -f "$BACKUP_DIR/$BACKUP_NAME.tmp" "$BACKUP_DIR/$BACKUP_NAME"
        echo "Successfully dumped $DB_NAME"
    else
        echo "Error dumping $DB_NAME" >&2
        rm -f "$BACKUP_DIR/$BACKUP_NAME.tmp"
        exit_status=1  # Fail at end so other databases may get backed up
    fi
done

# Keep only the 5 most recent backups for each database
for DB_NAME in $DATABASES; do
    # shellcheck disable=SC2012
    ls -1t "$BACKUP_DIR/$DB_NAME."*.sql.zst 2>/dev/null | tail -n +6 | xargs -r rm -f
done

echo "MySQL database backup completed."
echo "$exit_status"
