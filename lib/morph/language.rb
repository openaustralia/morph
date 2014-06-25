module Morph
  class Language
    LANGUAGES_SUPPORTED = [:ruby, :php, :python, :perl]

    WEBSITES = {
      ruby: "https://www.ruby-lang.org/en/",
      php: "http://www.php.net/",
      python: "https://www.python.org/",
      perl: "http://www.perl.org/"
    }

    HUMAN = {ruby: "Ruby", php: "PHP", python: "Python", perl: "Perl" }

    FILE_EXTENSIONS = {ruby: "rb", php: "php", python: "py", perl: "pl"}

    BINARY_NAMES = {
      # Run a special script of ours before anything else which switches off
      # buffering on stdout and stderr
      ruby: "ruby -r/usr/local/lib/prerun.rb",
      php: "php",
      # -u turns off buffering for stdout and stderr
      python: "python -u",
      perl: "perl"
    }

    attr_reader :key

    def initialize(key)
      @key = key
    end

    # Find the language of the code in the given directory
    def self.language2(repo_path)
      languages_supported2.find do |language|
        File.exists?(File.join(repo_path, language.scraper_filename))
      end
    end

    def self.languages_supported2
      LANGUAGES_SUPPORTED.map{|l| Language.new(l)}
    end

    def human
      t = HUMAN[key]
      raise "Unsupported language" if t.nil?
      t
    end

    def website
      WEBSITES[key]
    end

    def image_path
      "languages/#{key}.png"
    end

    def scraper_filename
      "scraper.#{FILE_EXTENSIONS[key]}" if key
    end

    def scraper_command
      "#{language.binary_name} /repo/#{language.scraper_filename}"
    end

    def supported?
      LANGUAGES_SUPPORTED.include?(key)
    end

    def default_scraper
      Language.default_scraper(@key)
    end

    def binary_name
      BINARY_NAMES[key]
    end

    private

    def self.default_scraper(key)
      if key == :ruby
        File.read("default_files/ruby/scraper.rb")
      elsif key == :php
        File.read("default_files/php/scraper.php")
      elsif key == :python
        File.read("default_files/python/scraper.py")
      elsif key == :perl
        File.read("default_files/perl/scraper.pl")
      else
        raise "Not yet supported"
      end
    end
  end
end
