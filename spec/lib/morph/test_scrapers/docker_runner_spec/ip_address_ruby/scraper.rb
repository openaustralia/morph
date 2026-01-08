require 'socket'
address = Socket.ip_address_list.find do |i|
  i.ipv4? && !i.ipv4_loopback?
end
File.open("ip_address", "w") { |f| f << address.ip_address }
