class Scraperwiki
  attr_reader :short_name

  def initialize(short_name)
    @short_name = short_name
  end

  def sqlite_database
    content = Scraperwiki.content("https://classic.scraperwiki.com/scrapers/export_sqlite/#{short_name}/")
    raise content if content =~ /The dataproxy connection timed out, please retry/
    content
  end

  def get_scraperwiki_info
    url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{short_name}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
    JSON.parse(Scraperwiki.content(url)).first
  end

  def self.content(url)
    Faraday.get(url).body
  end
end