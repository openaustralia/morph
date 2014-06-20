module Morph
  module Backup
    def self.backup
      unless SiteSetting.read_only_mode
        puts "WARNING: The site is NOT in read-only mode. So, things might get updated during the backup."
      end
      backup_mysql
      backup_sqlite
      backup_redis
      system("tar cf db/backups/morph_backup.tar db/backups/*.bz2")
      FileUtils.rm_f("db/backups/mysql_backup.sql.bz2")
      FileUtils.rm_f("db/backups/sqlite_backup.tar.bz2")
      FileUtils.rm_f("db/backups/redis_backup.rdb.bz2")
    end

    def self.restore
      system("tar xf db/backups/morph_backup.tar")
      restore_mysql
      restore_sqlite
      restore_redis
      FileUtils.rm_f("db/backups/mysql_backup.sql.bz2")
      FileUtils.rm_f("db/backups/sqlite_backup.tar.bz2")
      FileUtils.rm_f("db/backups/redis_backup.rdb.bz2")
    end

    def self.backup_mysql
      puts "Removing any previous MySQL backup..."
      FileUtils.rm_f("db/backups/mysql_backup.sql")
      FileUtils.rm_f("db/backups/mysql_backup.sql.bz2")
      FileUtils.mkdir_p("db/backups")
      puts "Backing up MySQL..."
      system("mysqldump -u #{mysql_username} -p#{mysql_password} #{mysql_database} > db/backups/mysql_backup.sql")
      puts "Compressing MySQL backup..."
      system("bzip2 db/backups/mysql_backup.sql")
    end

    def self.restore_mysql
      puts "Uncompressing MySQL backup..."
      system("bunzip2 -k db/backups/mysql_backup.sql.bz2")
      puts "Restoring from MySQL backup..."
      system("mysql -u #{mysql_username} -p#{mysql_password} #{mysql_database} < db/backups/mysql_backup.sql")
      FileUtils.rm_f("db/backups/mysql_backup.sql")
    end

    def self.backup_sqlite
      puts "Removing any previous SQLite backup..."
      FileUtils.rm_f("db/backups/sqlite_backup.tar")
      FileUtils.rm_f("db/backups/sqlite_backup.tar.bz2")
      puts "Backup up SQLite..."
      # TODO How shall we maintain permissions?
      system("tar cf db/backups/sqlite_backup.tar db/scrapers/data")
      puts "Compressing SQLite backup..."
      system("bzip2 db/backups/sqlite_backup.tar")
    end

    def self.restore_sqlite
      puts "Uncompressing SQLite backup..."
      system("bunzip2 -k db/backups/sqlite_backup.tar.bz2")
      puts "Restoring from SQLite backup..."
      system("tar xf db/backups/sqlite_backup.tar")
      FileUtils.rm_f("db/backups/sqlite_backup.tar")
    end

    def self.backup_redis
      puts "Removing any previous Redis backup..."
      FileUtils.rm_f("db/backups/redis_backup.rdb")
      FileUtils.rm_f("db/backups/redis_backup.rdb.bz2")
      puts "Redis taking snapshot..."
      redis = Redis.new
      redis.save
      puts "Backing up Redis..."
      system("cp #{redis_directory}/dump.rdb db/backups/redis_backup.rdb")
      puts "Compressing Redis backup..."
      system("bzip2 db/backups/redis_backup.rdb")
    end

    def self.restore_redis
      puts "Uncompressing Redis backup..."
      system("bunzip2 -k db/backups/redis_backup.rdb.bz2")
      puts "Restore from Redis backup..."
      system("mv db/backups/redis_backup.rdb #{redis_directory}/dump.rdb")
    end

    private

    def self.redis_directory
      "/usr/local/var/db/redis"
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
