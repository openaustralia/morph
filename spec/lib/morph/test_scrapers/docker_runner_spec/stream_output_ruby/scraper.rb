puts "Started!"
(1..10).each do |i|
  $stdout.puts "#{i}..."
  $stdout.flush
  sleep 0.1
end
puts "Finished!"
