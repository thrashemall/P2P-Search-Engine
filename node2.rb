require_relative 'peer_search_simplified.rb'

if ARGV[0] == "--boot_port"
  bootstrap_port = ARGV[1].to_i

  node2 = PeerSearchSimplified.new(createSocket(bootstrap_port+4))

  node2.joinNetwork(bootstrap_port, "jhon", "jane")
  # Node2 has joined but never listens, i.e. simulated an expected drop

  node4 = PeerSearchSimplified.new(createSocket(bootstrap_port+7))

  node4.joinNetwork(bootstrap_port, "paul", "jane")

  #test urls
  urls = ["www.help.org", "www.ruby.org", "www.pluckit.io"]
  node4.indexPage(urls, ["jane", "james"])
  results = node4.search(["jane", "james"])

  File.open("testfile.json", "w") do |file|
    file.puts results.geturls
  end
else
  puts "Incorrect input parameters"
end