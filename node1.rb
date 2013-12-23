require_relative 'peer_search_simplified.rb'

bootstrap_port = 8775
node1 = PeerSearchSimplified.new(createSocket(bootstrap_port+3))

node1.joinNetwork(bootstrap_port, "jane", "james") # bootstrap port address, node1 id, bootstrap_id(to route to)

node1.listen