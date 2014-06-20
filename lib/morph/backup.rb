module Morph
  module Backup
    def self.backup_mysql
      unless SiteSetting.read_only_mode
        puts "WARNING: The site is NOT in read-only mode. So, things might get updated during the backup."
      end
      FileUtils.mkdir_p("db/backups")
      puts "Backing up MySQL..."
      system("mysqldump -u scraping -pscraping scraping_development > db/backups/mysql_backup.sql")
      puts "Compressing MySQL backup..."
      system("bzip2 db/backups/mysql_backup.sql")
    end

    def self.restore_mysql
      puts "Uncompressing MySQL backup..."
      system("bunzip2 -k db/backups/mysql_backup.sql.bz2")
      puts "Restoring from MySQL backup..."
      system("mysql -u scraping -pscraping scraping_development < db/backups/mysql_backup.sql")
      FileUtils.rm_f("db/backups/mysql_backup.sql")
    end
  end
end
