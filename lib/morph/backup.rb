module Morph
  module Backup
    def self.backup
      unless SiteSetting.read_only_mode
        puts "WARNING: The site is NOT in read-only mode. So, things might get updated during the backup."
      end
      backup_mysql
    end

    def self.restore
      restore_mysql
    end

    def self.backup_mysql
      puts "Removing any previous backup..."
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

    private

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
