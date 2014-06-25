module Morph
  class Scraperwiki
    attr_reader :short_name

    def initialize(short_name)
      @short_name = short_name
    end

    def sqlite_database
      if @sqlite_database.nil?
        content = Morph::Scraperwiki.content("https://classic.scraperwiki.com/scrapers/export_sqlite/#{short_name}.sqlite")
        raise content if content =~ /The dataproxy connection timed out, please retry/
        @sqlite_database = content
      end
      @sqlite_database
    end

    def info
      raise 'short_name not set' if short_name.blank?
      if @info.nil?
        url = "https://classic.scraperwiki.com/scrapers/#{short_name}/info.json"
        content = Morph::Scraperwiki.content(url)
        v = JSON.parse(content) unless content.blank?
        if v.nil? || (v.kind_of?(Hash) && v["error"] == "Sorry, this scraper does not exist")
          @info = nil
        else
          @info = v.first
        end
      end
      @info
    end

    def translated_code
      Morph::CodeTranslate.translate(language, code)
    end

    def exists?
      !short_name.blank? && !!info
    end

    def view?
      language == :html
    end

    def private_scraper?
      exists? && info && info.has_key?("error") && info["error"] == "Invalid API Key"
    end

    def code
      info["code"]
    end

    def title
      info["title"]
    end

    def description
      info["description"]
    end

    def language
      if exists? && info && info.has_key?("language")
        info["language"].to_sym
      end
    end

    def language2
      Morph::Language.new(language)
    end

    def self.content(url)
      a = Faraday.get(url)
      a.body if a.success?
    end
  end
end
