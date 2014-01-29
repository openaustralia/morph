class Language
  # Defines our naming convention for the scraper of each language
  def self.language_to_file_extension(language)
    case language
    when :ruby
      "rb"
    when :php
      "php"
    when :python
      "py"
    end
  end

  def self.language_to_scraper_filename(language)
    "scraper.#{language_to_file_extension(language)}" if language
  end

  # Find the language of the code in the given directory
  def self.language(repo_path)
    [:ruby, :python, :php].find do |language|
      File.exists?(File.join(repo_path, language_to_scraper_filename(language)))
    end
  end

  def self.main_scraper_filename(repo_path)
    language_to_scraper_filename(language(repo_path))
  end

  def self.scraper_command(language)
    case language
    when :ruby
      "ruby /repo/#{language_to_scraper_filename(language)}"
    when :php
      "php /repo/#{language_to_scraper_filename(language)}"
    when :python
      "python /repo/#{language_to_scraper_filename(language)}"
    end
  end

  def self.language_supported?(language)
    [:ruby, :php, :python].include?(language)
  end
end