require 'scraperwiki'
require "open-uri"

puts "Running scraper"
ScraperWiki.save_sqlite(["name"], { "name" => "susan", "occupation" => "software developer", "time" => Time.now })
