class Database
  attr_reader :scraper
  delegate :data_path, to: :scraper

  def initialize(scraper)
    @scraper = scraper
  end

  def self.sqlite_db_filename
    "data.sqlite"
  end

  def self.sqlite_table_name
    "data"
  end

  def sqlite_db_path
    File.join(data_path, Database.sqlite_db_filename)
  end

  def sql_query(query, readonly = true)
    db = SQLite3::Database.new(sqlite_db_path, results_as_hash: true, type_translation: true, readonly: readonly)
    # If database is busy wait 5s
    db.busy_timeout(5000)
    db.execute(query)
  end

  def sql_query_safe(query, readonly = true)
    begin
      sql_query(query, readonly)
    rescue SQLite3::CantOpenException, SQLite3::SQLException, SQLite3::NotADatabaseException
      nil
    end
  end

  def no_rows
    sql_query_safe("select count(*) from #{Database.sqlite_table_name}").first.values.first
  end

  def sqlite_db_size
    if File.exists?(sqlite_db_path)
      File::Stat.new(sqlite_db_path).size
    else
      0
    end
  end

  def clear
    FileUtils.rm sqlite_db_path
  end

  def write_sqlite_database(content)
    FileUtils.mkdir_p data_path
    File.open(sqlite_db_path, 'wb') {|file| file.write(content) }
  end

  def standardise_table_name(table_name)
    sql_query_safe("ALTER TABLE #{table_name} RENAME TO #{Database.sqlite_table_name}", false)
  end

  def select_first_ten
    "select * from #{Database.sqlite_table_name} limit 10"
  end

  def select_all
    "select * from #{Database.sqlite_table_name}"
  end

  def first_ten_rows
    sql_query_safe(select_first_ten)
  end

  def self.tidy_data_path(data_path)
    # First get all the files in the data directory
    filenames = Dir.entries(data_path)
    filenames.delete(".")
    filenames.delete("..")
    filenames.delete(sqlite_db_filename)
    FileUtils.rm_rf filenames.map{|f| File.join(data_path, f)}
  end

  # Remove any files or directories in the data_path that are not the actual database
  def tidy_data_path
    Database.tidy_data_path(data_path)
  end
end