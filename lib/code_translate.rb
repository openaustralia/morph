class CodeTranslate
  # Translate Ruby code on ScraperWiki to something that will run on Morph
  # Adds "require 'scraperwiki'" to the top of the scraper code
  # but only if it's necessary
  def self.ruby(code)
    if code =~ /require ['"]scraperwiki['"]/
      code
    else
      code = "require 'scraperwiki'\n" + code
    end
  end
end