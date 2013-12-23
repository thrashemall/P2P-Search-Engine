require 'socket'
require 'json'
require 'timeout'

$machine_address = "127.0.0.1"
$bootstrap_address =  "127.0.0.1"

class SearchResult
  def initialize()
    @words = []
    @url = []
  end

  def puturls(urls)
    @url << urls
  end

  def putwords(words)
    @words << words
  end

  def geturls
    return @url
  end
end

def createSocket(port)
  begin
    socket = UDPSocket.new
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    socket.bind($machine_address, port)
  rescue StandardError => ex
    raise "cannot initialize UDP Socket for port #{port}: #{ex}"
    socket.close
  end
  return socket
end

def hashcode(string)
  hash = 0
  string.each_char do |i|
    hash = hash * 31 + i.unpack('H*')[0].to_i
  end
  return hash.abs
end

class PeerSearchSimplified
  def initialize(socket)
    @socket = socket
    @node_id = ""
    @table = []
    @index= Hash[]
    @ipaddress = @socket.addr[2].to_s # address: "127.0.0.1"
    @port = @socket.addr[1].to_s
    #@SearchResults search(words)
  end

  def init(socket)

  end

  def make_bootstrap(identifier)
    @node_id = hashcode(identifier)
    #updateTable(@node_id, @port)
  end
  # for the case of runing on one machine the bootstrap node parameter consists of the port number rather than the ip address
  def joinNetwork(bootstrap_node, identifier, target_identifier)
    file = open( "messages/joining_network_simplified.json")
    jsonMsg= JSON.load(file)
    #Assign the message parameters, bootstrap_address, target node ID and node identifier
    @node_id = hashcode(identifier)
    jsonMsg["node_id"] = @node_id
    jsonMsg["target_id"] = hashcode(target_identifier)
    jsonMsg["ip_address"] = @port
    puts "------- Node: %s in Port: %s Initialized Name: %s-------" %[@node_id,@port,identifier]
    msg = JSON.generate(jsonMsg)
    socketSend(msg, bootstrap_node )
    p " Message sent to #{bootstrap_node}: "
    p msg

    begin
      timeout(5) do
        msg, client = @socket.recvfrom(1024)
        puts "Message Recieved:"
        puts msg
        jsonMsg = JSON.parse(msg)
        route_table = jsonMsg["route_table"]
        #updateTable(@node_id, @port)
        for node in route_table
           updated_table = updateTable(node["node_id"],node["ip_address"])
        end
        puts "Node: %s Joined Network" %@node_id
        puts "Table updated"
        puts updated_table
      end
    rescue Timeout::Error
      puts "Timed out in Leave Network()! Socket closed!"
    end
    return @port
  end

  def leaveNetwork # parameter is previously returned peer network
    file = open( "messages/leaving_network.json")
    jsonMsg= JSON.load(file)
    jsonMsg["node_id"] = @node_id
    msg  = JSON.generate(jsonMsg)
    for node in @table

    end
    @socket.close
  end

  def search(words)
    result = SearchResult.new
    result.putwords(words)
    for word in words
      file = open( "messages/search.json")
      jsonMsg= JSON.load(file)

      jsonMsg["word"] = word
      jsonMsg["node_id"] = hashcode(word) #a non-negative number of order 2'^32^', indicating the target node (and also the id of the joining node).
      jsonMsg["sender_id"] =  @node_id
      msg = JSON.generate(jsonMsg)
      relayMessage(msg, jsonMsg["node_id"])
    end
    response = []
    begin
      timeout(5) do
        loop do
          msg, client = @socket.recvfrom(1024)
          jsonMsg = JSON.parse(msg)
          msgResponse = handleMessage(jsonMsg)
          words.delete(msgResponse["word"])
          result = SearchResult.new
          response << msgResponse["response"]
        end
      end
        #Send PING message to Node which did not send SEARCH_RESPONSE
    rescue Timeout::Error
      if !words.empty?
        words.each { |word|
          pingMessage(hashcode(word), @node_id, @port)
        }
      end
    end
    result.puturls(response)
    return result
  end

  # Takes in the node_id and node address of a node to be stored in the routing table
  def updateTable(node_id, node_address)
    newNode = Hash["node_id", node_id, "ip_address", node_address]
    for hash in @table
      if hash.has_value?(node_id)
        p "Node #{node_id} already in Table:"
        p @table
        newNode = 0
      end
    end
    #if @table.empty?
    #  newNode = Hash["node_id", node_id, "ip_address", node_address]
    #end
    if newNode != 0
      @table << newNode
    end
    return @table
  end

  def removeFromTable(node_id)
    for node in @table
      if node["node_id"] == node_id
        @table.delete(node)
      end
    end
    puts "Table Updated (Node Removed): "
    puts @table
  end

  def searchClosestNode(id)
    current = Hash["node_id", (2**31).to_s, "ip_address", "0"]
    for table_node in @table
      if current["node_id"].to_i > distance(table_node["node_id"],id) && table_node["node_id"] != @node_id
        closestNode = table_node
      end
      if distance(table_node["node_id"],id) == 0
        puts "Closest Node Search for Node: #{id}"
        puts closestNode
        puts "in Table:"
        puts @table
        return closestNode
      end
    end
    puts "Closest Node Search for Node: #{id}"
    puts closestNode
    puts "in Table:"
    puts @table
    return closestNode
  end

  def distance(a,b)
    a = a.to_i
    b = b.to_i
    return a ^ b
  end

  def sendRoutingInfo(gateway_id, target_id)
    file = open( "messages/routing_info.json")
    jsonMsg= JSON.load(file)
    jsonMsg["node_id"] = target_id #a non-negative number of order 2'^32^', indicating the target node (and also the id of the joining node).
    jsonMsg["gateway_id"] = gateway_id #a non-negative number of order 2'^32^', of the gateway node
    jsonMsg["ip_address"] = @port #the ip address of the node sending the routing information
    jsonMsg["route_table"] = @table << Hash["node_id", @node_id, "ip_address", @port]
    if jsonMsg["gateway_id"] == @node_id
      closestNode = searchClosestNode(jsonMsg["node_id"])
    else
      closestNode = searchClosestNode(jsonMsg["gateway_id"])
    end
        msg = JSON.generate(jsonMsg)
    #puts "CLOSEST NODE to NODE: %s IS NODE: %s " %[target_id, closestNode["node_id"]]
    socketSend(msg,closestNode["ip_address"])
    puts "Routing Info Sent to Node: %s" %closestNode["ip_address"]
  end

  def sendJoiningNetworkRelay(gateway_id, joining_node, target_id)
    file = open( "messages/joining_network_relay_simplified.json")
    jsonMsg= JSON.load(file)
    jsonMsg["node_id"] = joining_node #a non-negative number of order 2'^32^', indicating the target node (and also the id of the joining node).
    jsonMsg["target_id"] = target_id
    jsonMsg["gateway_id"] = gateway_id #a non-negative number of order 2'^32^', of the gateway node
    closestNode = searchClosestNode(jsonMsg["target_id"])
    msg = JSON.generate(jsonMsg)
    socketSend(msg,closestNode["ip_address"])
    puts "Relay Sent to: "
    puts closestNode
  end

  def relayMessage(msg, target_id)
    closestNode = searchClosestNode(target_id)
    socketSend(msg,closestNode["ip_address"])
  end

  def indexPage(links, keywords)
    numWords = keywords.size
    for keyword in keywords
      file = open( "messages/index.json")
      jsonMsg= JSON.load(file)
      target_id = hashcode(keyword)

      jsonMsg["target_id"] = target_id
      jsonMsg["sender_id"] = @node_id #a non-negative number of order 2'^32^', indicating the target node (and also the id of the joining node).
      jsonMsg["keyword"] = keyword
      jsonMsg["link"] = links

      msg = JSON.generate(jsonMsg)
      closestNode = searchClosestNode(jsonMsg["target_id"])
      socketSend(msg,closestNode["ip_address"])
      puts " Index Sent to Node: #{closestNode["node_id"]} ----> Node: #{jsonMsg["target_id"]}"
      # Wait to recieve ACK_INDEX
      begin
        status = -1
        timeout(5) do
         # numWords.times do
            msg, client = @socket.recvfrom(1024)
            jsonMsg = JSON.parse(msg)
            status = handleMessage(jsonMsg)
         # end
        end
      #Send PING message if necessary
      rescue Timeout::Error
        if status == -1
          pingMessage(target_id, @node_id, @port)
        end
      end
    end
  end

  def socketSend(msg,address)
    @socket.send(msg, 0 ,"127.0.0.1", address)
  end
  def pingMessage(target_id, sender_id, ip_address)
    file = open( "messages/ping.json")
    jsonMsg= JSON.load(file)

    jsonMsg["target_id"] = target_id
    jsonMsg["sender_id"] = sender_id #a non-negative number of order 2'^32^', indicating the target node (and also the id of the joining node).
    jsonMsg["ip_address"] = ip_address

    msg = JSON.generate(jsonMsg)
    closestNode = searchClosestNode(jsonMsg["target_id"])
    socketSend(msg,closestNode["ip_address"])
    puts " PING Sent to Node: #{closestNode["node_id"]} ----> Node: #{jsonMsg["target_id"]}"

    begin
      status = -1
      timeout(5) do
        msg, client = @socket.recvfrom(1024)
        jsonMsg = JSON.parse(msg)
        status = handleMessage(jsonMsg)
      end
    rescue Timeout::Error
      if status == -1
        removeFromTable(target_id)
      end
    end
  end

  # Determine what to do, depending on the message type
  def handleMessage(jsonMsg)
    if jsonMsg["type"] == "JOINING_NETWORK_SIMPLIFIED" then
      if jsonMsg["target_id"] == @node_id # if the target ID is the current node then
        puts "Updating Table..."
        table = updateTable(jsonMsg["node_id"], jsonMsg["ip_address"])

        sendRoutingInfo(@node_id, jsonMsg["node_id"])
      else
        puts "relaying Msg to Network...."
        sendJoiningNetworkRelay(@node_id, jsonMsg["node_id"], jsonMsg["target_id"])
        updateTable(jsonMsg["node_id"], jsonMsg["ip_address"])
      end

    elsif jsonMsg["type"] == "JOINING_NETWORK_RELAY_SIMPLIFIED" then
      if jsonMsg["target_id"] == @node_id
        puts "Joining Network Relay Message Arrived to Target Node: %s " %@node_id
        sendRoutingInfo(jsonMsg["gateway_id"], jsonMsg["node_id"])
      else
        #Forward on the message through the network
        sendJoiningNetworkRelay(jsonMsg["gateway_id"], jsonMsg["node_id"], jsonMsg["target_id"])
        updateTable(jsonMsg["node_id"], jsonMsg["ip_address"])
      end

    elsif jsonMsg["type"] == "ROUTING_INFO" then
      if jsonMsg["gateway_id"] == @node_id
        puts "HANDLING ROUTING INFO MESSAGE..."
        for newNode in jsonMsg["route_table"]
          table = updateTable(newNode["node_id"], newNode["ip_address"])
        end
        sendRoutingInfo(jsonMsg["gateway_id"], jsonMsg["node_id"])
      end

    elsif jsonMsg["type"] == "LEAVING_NETWORK" then
      removeFromTable(jsonMsg["node_id"])

    elsif jsonMsg["type"] == "INDEX" then
      puts "INDEX Recieved"
      sender_id = jsonMsg["sender_id"]
      keyword  = jsonMsg["keyword"]
      if jsonMsg["target_id"] == @node_id
        ###Index the page into database
        # Check for word- URL mapping and append to index or update page rank
        indexed = 0
        @index.each { |word, links|

          if word == jsonMsg["keyword"]
            for newlink in jsonMsg["link"]
              indexed = 0
              for link in links
                if link["url"]== newlink
                  link["rank"] = link["rank"] + 1
                  indexed = 1
                end
              end
              if indexed == 0
                links << Hash["url", newlink, "rank", 1]
                indexed = 1
              end
              @index[word] = links
            end
          end
        }
        if indexed == 0
          links = []
          for newlink in jsonMsg["link"]
            links << Hash["url", newlink, "rank", 1]
          end
          @index[jsonMsg["keyword"]] = links
        end
        #Send ACK
        file = open("messages/ack_index.json")
        jsonMsg= JSON.load(file)

        jsonMsg["node_id"] = sender_id
        jsonMsg["keyword"] = keyword
        msg = JSON.generate(jsonMsg)
        relayMessage(msg, sender_id)
      else
        msg = JSON.generate(jsonMsg)
        relayMessage(msg, jsonMsg["target_id"])
        puts "INDEX Relayed to Target Node: #{jsonMsg["target_id"]}"
      return @index
      end

    elsif jsonMsg["type"] == "ACK_INDEX" then
      puts "ACK_INDEX Arrived at Target Node: #{jsonMsg["node_id"]} for Keyword: #{jsonMsg["keyword"]}"
      return jsonMsg["keyword"]

    elsif jsonMsg["type"] == "PING" then
      if jsonMsg["target_id"] == @node_id
        sendingNodeAddr = jsonMsg["ip_address"]
        puts "PING Arrived at Target node: #{jsonMsg["target_id"]}"
        #Send ACK
        file = open( "messages/ack.json")
        jsonMsg= JSON.load(file)

        jsonMsg["node_id"] = @node_id
        jsonMsg["ip_address"] = @port

        msg = JSON.generate(jsonMsg)
        socketSend(msg, sendingNodeAddr)
      else # if PING message has not arrived at Target Node
        jsonMsg["ip_address"] = @port
        pingMessage(jsonMsg["target_id"],jsonMsg["node_id"], @port)
        puts "PING Relayed to Target Node: #{jsonMsg["target_id"]}"
      end

    elsif jsonMsg["type"] == "ACK" then
      puts "PING_ACK Recieved"
      #
      return jsonMsg["node_id"]

    elsif jsonMsg["type"] == "SEARCH"
      if jsonMsg["node_id"] == @node_id
        target_id = jsonMsg["sender_id"]
        word = jsonMsg["word"]
        puts "SEARCH Arrived at Target Node: #{@node_id}"
        result = lookupIndex(word)

        file = open( "messages/search_response.json")
        jsonMsg= JSON.load(file)

        jsonMsg["word"] = word
        jsonMsg["node_id"] = target_id
        jsonMsg["sender_id"] = @node_id
        jsonMsg["response"] = result

        msg = JSON.generate(jsonMsg)
        relayMessage(msg, target_id)
        puts "SEARCH Result for Word: '#{jsonMsg["word"]}' Relayed to Node: #{jsonMsg["node_id"]}"
      else
        msg = JSON.generate(jsonMsg)
        relayMessage(msg, jsonMsg["node_id"])
        puts "SEARCH Message Relayed to Target Node: #{jsonMsg["target_id"]}"
      end

    elsif jsonMsg["type"] == "SEARCH_RESPONSE"
      if jsonMsg["node_id"] == @node_id
        puts "SEARCH_RESPONSE for Word: #{jsonMsg["word"]} Arrived at Target Node: #{@node_id}"
        return jsonMsg
      else
        msg = JSON.generate(jsonMsg)
        relayMessage(msg, jsonMsg["node_id"])
        puts "SEARCH Relayed for Word: #{jsonMsg["word"]} to Target Node: #{jsonMsg["target_id"]}"
      end
    end
  end

  def lookupIndex(keyword)
    #Looks at the index database for keyword match
    @index.each { |word, links|
      if word == keyword
        #returns the urls
        return links
      end
    }
    return []
  end
  def appendLinks(indexlinks, newlink)
      currlink = []
      indexed = 0
      for indexlink in indexlinks
        if newlink == indexlink["url"]
          p newlink
          #indexlink["rank"] = indexlink["rank"].to_i + 1
          #count the frequency
          indexed = 1
          p "url frequency updated"
        else
          indexlinks << Hash["url", newlink, "rank", 1]
          p "new URL indexed"
          indexed = 1
        end
        currlink = indexlinks
      end
        indexlinks << currlink
    #end
    return indexlinks
  end

  def listen()
    begin
      timeout(40) do
        10.times do
          msg, client  = @socket.recvfrom(1024) #=> "aaa"
          puts "Message Recieved: '%s'" % msg
          jsonMsg = JSON.parse(msg)
          handleMessage(jsonMsg)
        end
      end
    rescue Timeout::Error
      puts "Timout in Listen occurred"
    ensure
      @socket.close
    end
  end
end




