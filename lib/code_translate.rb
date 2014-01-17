module CodeTranslate
  # Translate Ruby code on ScraperWiki to something that will run on Morph
  def self.translate(language, code)
    case language
    when :ruby
      Ruby::translate(code)
    when :php
      PHP::translate(code)
    when :python
      Python::translate(code)
    else
      raise "unsupported language"
    end
  end

  def self.sql(sql)
    sql.gsub('swdata', 'data')
  end

  module PHP
    def self.translate(code)
      change_table_in_select(add_require(code))
    end

    # Add require immediately after "<?php"
    def self.add_require(code)
      if code =~ /require 'scraperwiki.php'/
        code
      else      
        code.sub(/<\?php/, "<?php\nrequire 'scraperwiki.php'")
      end
    end

    def self.change_table_in_select(code)
      code.gsub(/scraperwiki::select\((['"])(.*)(['"])(.*)\)/) do |s|
        "scraperwiki::select(#{$1}#{CodeTranslate.sql($2)}#{$3}#{$4})"
      end
    end
  end

  module Python
    def self.translate(code)
      code
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
        "ScraperWiki.#{$1}(#{$2}#{CodeTranslate.sql($3)}#{$4}#{$5})"
      end
    end
  end
end