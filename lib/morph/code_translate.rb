module Morph
  # Translate code on ScraperWiki to something that will run on morph.io
  module CodeTranslate
    def self.translate(language_key, code)
      case language_key
      when :ruby
        Ruby.translate(code)
      when :php
        PHP.translate(code)
      when :python
        Python.translate(code)
      else
        raise 'unsupported language'
      end
    end

    def self.sql(sql)
      sql.gsub('swdata', 'data')
    end

    # Translating PHP scraperwiki code
    module PHP
      def self.translate(code)
        change_table_in_select(add_require(code))
      end

      # Add require immediately after "<?php"
      def self.add_require(code)
        if code =~ /require ['"]scraperwiki.php['"]/
          code
        else
          code.sub(/<\?php/, "<?php\nrequire 'scraperwiki.php';")
        end
      end

      def self.change_table_in_select(code)
        code.gsub(/scraperwiki::select\((['"])(.*)(['"])(.*)\)/) do |_s|
          "scraperwiki::select(#{Regexp.last_match(1)}#{CodeTranslate.sql(Regexp.last_match(2))}#{Regexp.last_match(3)}#{Regexp.last_match(4)})"
        end
      end
    end

    # Translating Python scraperwiki code
    module Python
      def self.translate(code)
        code
      end
    end

    # Translating Ruby scraperwiki code
    module Ruby
      def self.translate(code)
        add_instructions_for_libraries(
          change_table_in_sqliteexecute_and_select(add_require(code))
        )
      end

      # If necessary adds "require 'scraperwiki'" to the top of the scraper code
      def self.add_require(code)
        if code =~ /require ['"]scraperwiki['"]/
          code
        else
          "require 'scraperwiki'\n" + code
        end
      end

      def self.change_table_in_sqliteexecute_and_select(code)
        code.gsub(
          /ScraperWiki.(sqliteexecute|select)\((['"])(.*)(['"])(.*)\)/
        ) do |_s|
          "ScraperWiki.#{Regexp.last_match(1)}(#{Regexp.last_match(2)}#{CodeTranslate.sql(Regexp.last_match(3))}#{Regexp.last_match(4)}#{Regexp.last_match(5)})"
        end
      end

      def self.add_instructions_for_libraries(code)
        code.gsub(%r{require ['"]scrapers/(.*)['"]}) do |s|
          i = <<-EOF
# TODO:
# 1. Fork the ScraperWiki library (if you haven't already) at https://classic.scraperwiki.com/scrapers/#{Regexp.last_match(1)}/
# 2. Add the forked repo as a git submodule in this repo
# 3. Change the line below to something like require File.dirname(__FILE__) + '/#{Regexp.last_match(1)}/scraper'
# 4. Remove these instructions
          EOF
          i + s
        end
      end
    end
  end
end
