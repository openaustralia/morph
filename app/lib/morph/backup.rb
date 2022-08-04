# typed: true
# frozen_string_literal: true

module Morph
  # Backup and restore to local files
  module Backup
    def self.backup
      unless SiteSetting.read_only_mode
        Rails.logger.warn "WARNING: The site is NOT in read-only mode. " \
                          "So, things might get updated during the backup."
      end
      backup_mysql
      backup_sqlite
      backup_redis
      system "tar cf db/backups/morph_backup.tar db/backups/*.bz2"
      FileUtils.rm_f "db/backups/mysql_backup.sql.bz2"
      FileUtils.rm_f "db/backups/sqlite_backup.tar.bz2"
      FileUtils.rm_f "db/backups/redis_backup.rdb.bz2"
    end

    def self.restore
      system "tar xf db/backups/morph_backup.tar"
      restore_mysql
      restore_sqlite
      restore_redis
      FileUtils.rm_f "db/backups/mysql_backup.sql.bz2"
      FileUtils.rm_f "db/backups/sqlite_backup.tar.bz2"
      FileUtils.rm_f "db/backups/redis_backup.rdb.bz2"
    end

    def self.backup_mysql
      Rails.logger.info "Removing any previous MySQL backup..."
      FileUtils.rm_f "db/backups/mysql_backup.sql"
      FileUtils.rm_f "db/backups/mysql_backup.sql.bz2"
      FileUtils.mkdir_p "db/backups"
      Rails.logger.info "Backing up MySQL..."
      system "mysqldump #{mysql_auth} #{mysql_database} " \
             "> db/backups/mysql_backup.sql"
      Rails.logger.info "Compressing MySQL backup..."
      system "bzip2 db/backups/mysql_backup.sql"
    end

    def self.restore_mysql
      Rails.logger.info "Uncompressing MySQL backup..."
      system "bunzip2 -k db/backups/mysql_backup.sql.bz2"
      Rails.logger.info "Restoring from MySQL backup..."
      system "mysql #{mysql_auth} #{mysql_database} " \
             "< db/backups/mysql_backup.sql"
      FileUtils.rm_f "db/backups/mysql_backup.sql"
    end

    def self.backup_sqlite
      Rails.logger.info "Removing any previous SQLite backup..."
      FileUtils.rm_f "db/backups/sqlite_backup.tar"
      FileUtils.rm_f "db/backups/sqlite_backup.tar.bz2"
      Rails.logger.info "Backup up SQLite..."
      # TODO: How shall we maintain permissions?
      system "tar cf db/backups/sqlite_backup.tar db/scrapers/data"
      Rails.logger.info "Compressing SQLite backup..."
      system "bzip2 db/backups/sqlite_backup.tar"
    end

    def self.restore_sqlite
      Rails.logger.info "Uncompressing SQLite backup..."
      system "bunzip2 -k db/backups/sqlite_backup.tar.bz2"
      Rails.logger.info "Restoring from SQLite backup..."
      system "tar xf db/backups/sqlite_backup.tar"
      FileUtils.rm_f "db/backups/sqlite_backup.tar"
    end

    def self.backup_redis
      Rails.logger.info "Removing any previous Redis backup..."
      FileUtils.rm_f "db/backups/redis_backup.rdb"
      FileUtils.rm_f "db/backups/redis_backup.rdb.bz2"
      Rails.logger.info "Redis taking snapshot..."
      redis = Redis.new
      redis.save
      Rails.logger.info "Backing up Redis..."
      system "cp #{redis_directory}/dump.rdb db/backups/redis_backup.rdb"
      Rails.logger.info "Compressing Redis backup..."
      system "bzip2 db/backups/redis_backup.rdb"
    end

    def self.restore_redis
      Rails.logger.info "Uncompressing Redis backup..."
      system "bunzip2 -k db/backups/redis_backup.rdb.bz2"
      Rails.logger.info "Restore from Redis backup..."
      system "mv db/backups/redis_backup.rdb #{redis_directory}/dump.rdb"
    end

    def self.redis_directory
      "/var/lib/redis"
    end

    def self.mysql_auth
      if mysql_username.blank? && mysql_password.blank?
        "-u root"
      else
        "-u #{mysql_username} -p#{mysql_password}"
      end
    end

    def self.mysql_configuration
      Rails.configuration.database_configuration[Rails.env]
    end

    def self.mysql_database
      mysql_configuration["database"]
    end

    def self.mysql_username
      mysql_configuration["username"]
    end

    def self.mysql_password
      mysql_configuration["password"]
    end
  end
end
