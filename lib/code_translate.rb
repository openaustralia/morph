class CodeTranslate
  # Translate Ruby code on ScraperWiki to something that will run on Morph
  def self.ruby(code)
    switch_to_scraperwiki_morph(add_require(code))
  end

  # If necessary adds "require 'scraperwiki'" to the top of the scraper code
  def self.add_require(code)
    if code =~ /require ['"]scraperwiki['"]/
      code.gsub(/require ['"]scraperwiki['"]/, "require 'scraperwiki-morph'")
    else
      code = "require 'scraperwiki-morph'\n" + code
    end
  end

  def self.switch_to_scraperwiki_morph(code)
    code.gsub(/ScraperWiki\./, "ScraperWikiMorph.")
  end
end