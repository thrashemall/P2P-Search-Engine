require_relative 'peer_search_simplified.rb'

if ARGV[0] == "--boot_port"
  bootstrap_port = ARGV[1].to_i
  node1 = PeerSearchSimplified.new(createSocket(bootstrap_port+3))

  node1.joinNetwork(bootstrap_port, "jane", "james") # bootstrap port address, node1 id, bootstrap_id(to route to)

  node1.listen
else
  puts "Incorrect input parameters"
end

