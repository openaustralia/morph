module Morph
  class Scraperwiki
    attr_reader :short_name

    def initialize(short_name)
      @short_name = short_name
    end

    def sqlite_database
      if @sqlite_database.nil?
        content = Morph::Scraperwiki.content("https://classic.scraperwiki.com/scrapers/export_sqlite/#{short_name}/")
        raise content if content =~ /The dataproxy connection timed out, please retry/
        @sqlite_database = content
      end
      @sqlite_database
    end

    def info
      if @info.nil?
        url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{short_name}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
        @info = JSON.parse(Morph::Scraperwiki.content(url)).first
      end
      @info
    end

    def translated_code
      Morph::CodeTranslate.translate(language, code)
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
      info["language"].to_sym
    end

    def self.content(url)
      Faraday.get(url).body
    end
  end
end