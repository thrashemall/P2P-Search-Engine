require_relative 'peer_search_simplified.rb'

if ARGV[0] == "--boot"
  bootstrap_id = ARGV[1]
  if ARGV[2] == "--port"
    bootstrap_port = ARGV[3]
  end
  bootstrap_node = PeerSearchSimplified.new(createSocket(bootstrap_port))
  bootstrap_node.make_bootstrap(bootstrap_id)
  bootstrap_node.listen
end
