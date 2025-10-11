#!/usr/bin/env ruby
# frozen_string_literal: true

# This is a template for a Ruby scraper on morph.io (https://morph.io)

Bundler.require

require "scraperwiki"
require "mechanize"

class Scraper
  def self.run
    agent = Mechanize.new

    # Read in a page
    page = agent.get("https://example.com")

    # Find something on the page using css selectors
    page.search("h1").each do |h1|
      value = h1.text.strip
      # Write out to the sqlite database using scraperwiki library
      ScraperWiki.save_sqlite(["name"], { "name" => value })
    end

    # An arbitrary query against the database
    rows = ScraperWiki.select("rowid AS id, name FROM data ORDER BY rowid desc LIMIT 3")
    rows.each do |row|
      puts "#{row['id']}: #{row['name']}"
    end
  end
end

# Run the scraper whilst allowing this file to be required in tests without auto-execution
Scraper.run if __FILE__ == $PROGRAM_NAME

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
