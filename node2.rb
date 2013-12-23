require_relative 'peer_search_simplified.rb'

bootstrap_port = 8775

node2 = PeerSearchSimplified.new(createSocket(bootstrap_port+4))

node2.joinNetwork(bootstrap_port, "jhon", "jane")

#node2.listen
node4 = PeerSearchSimplified.new(createSocket(bootstrap_port+7))

node4.joinNetwork(bootstrap_port, "paul", "jane")

urls = ["www.help.org", "www.ruby.org", "www.pluckit.io"]

node4.indexPage(urls, ["jane", "james"])
results = node4.search(["jane", "james"])

File.open("testfile.json", "w") do |file|
  file.puts results.geturls
end

#node4.pingMessage(hashcode("c"), hashcode("e"), bootstrap_port+7)