require 'scraperwiki'

puts "Started!"
ScraperWiki.save_sqlite(["state"], {"state" => "started"})
(1..50).each do |i|
  puts "#{i}..."
  sleep 0.1
end
puts "Finished!"
ScraperWiki.save_sqlite(["state"], {"state" => "finished"})
