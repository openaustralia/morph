module CodeTranslate
  # Translate Ruby code on ScraperWiki to something that will run on Morph
  def self.translate(language, code)
    case language
    when :ruby
      Ruby::translate(code)
    when :php, :python
      code
    else
      raise "unsupported language"
    end
  end

  module Ruby
    def self.translate(code)
      switch_to_scraperwiki_morph(change_table_in_sqliteexecute_and_select(add_require(code)))
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

    def self.change_table_in_sqliteexecute_and_select(code)
      code.gsub(/ScraperWiki.(sqliteexecute|select)\((['"])(.*)(['"])(.*)\)/) do |s|
        method, bracket1, sql, bracket2, rest = $1, $2, $3, $4, $5
        sql = sql.gsub('swdata', 'data')
        "ScraperWiki.#{method}(#{bracket1}#{sql}#{bracket2}#{rest})"
      end
    end
  end
end