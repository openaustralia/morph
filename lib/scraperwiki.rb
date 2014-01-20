class Scraperwiki
  attr_reader :short_name

  def initialize(short_name)
    @short_name = short_name
  end

  def sqlite_database
    response = Faraday.get("https://classic.scraperwiki.com/scrapers/export_sqlite/#{short_name}/")
    response.body
  end
end