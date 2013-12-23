require_relative 'peer_search_simplified.rb'

bootstrap_port = 8775
bootstrap_node = PeerSearchSimplified.new(createSocket(bootstrap_port))
bootstrap_node.make_bootstrap("james")
bootstrap_node.listen
#sleep(1000)

#bootstrap_node.leaveNetwork(bootstrap_port)







