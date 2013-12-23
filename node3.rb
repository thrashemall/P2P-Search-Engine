require_relative 'peer_search_simplified.rb'

bootstrap_port = 8775

node3 = PeerSearchSimplified.new(createSocket(bootstrap_port+5))

node3.joinNetwork(bootstrap_port+3, "peter", "jane")
urls2 = ["www.pluckit.io", "www.gmail.com"]
node3.indexPage(urls2, ["jane", "james"])

node3.listen

