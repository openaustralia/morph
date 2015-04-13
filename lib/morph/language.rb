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

    # Files are grouped together when they need to be treated as a unit
    # For instance in Ruby. Gemfile and Gemfile.lock always go together.
    # So, the default Gemfile and Gemfile.lock only get inserted if both
    # those files are missing
    DEFAULT_FILES_TO_INSERT = {
      ruby: [
        ["Gemfile", "Gemfile.lock"],
        ["Procfile"]
      ],
      python: [
        ["requirements.txt"],
        ["runtime.txt"],
        ["Procfile"]
      ],
      php: [
        ["composer.json", "composer.lock"],
        ["Procfile"]
      ],
      perl: [
        ["app.psgi"],
        ["cpanfile"],
        ["Procfile"]
      ]
    }

    attr_reader :key

    def initialize(key)
      @key = key
    end

    # Find the language of the code in the given directory
    def self.language(repo_path)
      languages_supported.find do |language|
        File.exists?(File.join(repo_path, language.scraper_filename))
      end
    end

    def self.languages_supported
      LANGUAGES_SUPPORTED.map{|l| Language.new(l)}
    end

    def default_files_to_insert
      DEFAULT_FILES_TO_INSERT[key]
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
      "#{binary_name} /repo/#{scraper_filename}"
    end

    def supported?
      LANGUAGES_SUPPORTED.include?(key)
    end

    def default_scraper
      if supported?
        default_file(scraper_filename)
      else
        raise "Not yet supported"
      end
    end

    def binary_name
      BINARY_NAMES[key]
    end

    def default_file_path(file)
      "default_files/#{key}/#{file}"
    end
  end
end
