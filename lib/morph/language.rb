module Morph
  class Language
    def self.languages_supported
      [:ruby, :php, :python]
    end

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

    # Name of the binary for running scripts of a particular language
    def self.binary_name(language)
      case language
      when :ruby
        "ruby"
      when :php
        "php"
      when :python
        "python"
      end
    end

    def self.language_to_scraper_filename(language)
      "scraper.#{language_to_file_extension(language)}" if language
    end

    # Find the language of the code in the given directory
    def self.language(repo_path)
      languages_supported.find do |language|
        File.exists?(File.join(repo_path, language_to_scraper_filename(language)))
      end
    end

    def self.main_scraper_filename(repo_path)
      language_to_scraper_filename(language(repo_path))
    end

    def self.scraper_command(language)
      "#{binary_name(language)} /repo/#{language_to_scraper_filename(language)}"
    end

    def self.language_supported?(language)
      languages_supported.include?(language)
    end
  end
end