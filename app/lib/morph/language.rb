# typed: false
# frozen_string_literal: true

module Morph
  # Special stuff for each scripting language supported by morph.io
  class Language
    LANGUAGES_SUPPORTED = %i[ruby php python perl nodejs].freeze

    WEBSITES = {
      ruby: "https://www.ruby-lang.org/en/",
      php: "http://www.php.net/",
      python: "https://www.python.org/",
      perl: "http://www.perl.org/",
      nodejs: "https://nodejs.org/"
    }.freeze

    HUMAN = { ruby: "Ruby", php: "PHP", python: "Python", perl: "Perl",
              nodejs: "Node.js" }.freeze

    FILE_EXTENSIONS = { ruby: "rb", php: "php", python: "py", perl: "pl",
                        nodejs: "js" }.freeze

    # Files are grouped together when they need to be treated as a unit
    # For instance in Ruby. Gemfile and Gemfile.lock always go together.
    # So, the default Gemfile and Gemfile.lock only get inserted if both
    # those files are missing
    DEFAULT_FILES_TO_INSERT = {
      ruby: [
        ["Gemfile", "Gemfile.lock"]
      ],
      python: [
        ["requirements.txt"],
        ["runtime.txt"]
      ],
      php: [
        ["composer.json", "composer.lock"]
      ],
      perl: [
        ["app.psgi"],
        ["cpanfile"]
      ],
      nodejs: []
    }.freeze

    BINARIES = {
      # Run a special script of ours before anything else which switches off
      # buffering on stdout and stderr
      ruby: "bundle exec ruby -r/usr/local/lib/prerun.rb",
      php: "php -d include_path=.:/app/vendor/openaustralia/scraperwiki",
      # -u turns off buffering for stdout and stderr
      python: "python -u",
      perl: "perl -Mlib=/app/local/lib/perl5",
      nodejs: "node --expose-gc"
    }.freeze

    attr_reader :key

    def initialize(key)
      @key = key
    end

    # Find the language of the code in the given directory
    def self.language(repo_path)
      languages_supported.find do |language|
        File.exist?(File.join(repo_path, language.scraper_filename))
      end
    end

    def self.languages_supported
      LANGUAGES_SUPPORTED.map { |l| Language.new(l) }
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

    def supported?
      LANGUAGES_SUPPORTED.include?(key)
    end

    def scraper_templates
      raise "Not yet supported" unless supported?

      # We grab all the files in the template directory
      result = {}
      Dir.entries(default_template_directory).each do |file|
        result[file] = File.read(File.join(default_template_directory, file)) if file != "." && file != ".."
      end
      result
    end

    def binary
      BINARIES[key]
    end

    def procfile
      "scraper: #{binary} #{scraper_filename}"
    end

    def default_config_file_path(file)
      "default_files/#{key}/config/#{file}"
    end

    def default_template_directory
      "default_files/#{key}/template"
    end

    def default_template_file_path(file)
      "#{default_template_directory}/#{file}"
    end
  end
end
