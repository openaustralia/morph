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

  def self.content(url)
    Faraday.get(url).body
  end
end