P2P-Search-Engine
=================

This Implementation consists of the peer_search_simplified.rb file which contains all the peer class implementation with corresponding methods

NOTE: that the system communicates between nodes, NOT by ip address but rather by distinct port numbers for each
corresponding node/peer. The reason for this is the fact that testing the system on one machine using the ip address
was not possble therefore I decided to leave it with port numbers as changing it as described in the protocol
(i.e. with the ip address varying) would be difficult to test with one machine.
Therefore this systems messaging protocol has been modified slightly, such that any message which contains
the "ip_address" field actually contains the nodes port number.

The bootstrap node can be called by doing the following in shell
# ruby nodes.rb --boot <bootstrap_node id> --port <port no.>
This will create the bootstrap node with corresponding id, and listen for incomming messages at port no.

NODES JOINING
The node1.rb (initializes node with id: "jane") , node2.rb (initializes node with id: "jhon"), node3.rb (initializes
node with id: "peter" and "paul"), and files when executed respectively as separate processes initialize 4 nodes.
Where each node joins the network via the bootstrap node's port, routing to the previous node initialized.

i.e. ..... Join Message Routing......
```
 "jane" -----> bootstrap
 "john" -----> "jane"
 "peter" -----> "jhon"
 "paul" -----> "peter"
```

The above .rb files must be called on separate terminals as each node has to run on its own process since each node polls
and blocks for messages to be received. Therefore if testing the code via a script then you may need to run each node on a separate thread

Running each node on a separate console with the node<x>.rb files configureing the corresponding nodes tests the system,
by instantiating a node with specified ID and port number and are set to listen in their corresponding ports for incomming messages.
Additionally the one node is just joined and does not listen, i.e. acting as a node that has left the network,
and two other nodes send INDEX messages accross the network, the data in the index message is then used when sending a
SEARCH message on the network looking for some of the content indexed.

This simple test showed that the system was working according to the developed protocol. However one bug to note is that the routing table
may contain duplicates. (unfortunately I had no more time left to fix this).

Sample Usage
-------------
nodes join the netork and listen for incoming messages as follows (in a .rb script):
```
require_relative 'peer_search_simplified'
....
bootstrap_port = 8781
node = PeerSearchSimplified.new(createSocket(bootstrap_port+1))
node.joinNetwork(bootstrap_port, "jane", "james") # bootstrap port address, node1 id, bootstrap_id(to route to)
node.listen

```

This will initialize a node with 1 port number, greater than the bootstrap_port.
NOTE: that nodes listen for maximum of 40 seconds and then close the socket, in order to ensure the socket will be reusable. This timout time can be easily change in the listen() method in the peer_search_simplified.rb file.

Nodes index and search for keyword and url pairs as follows:

```
require_relative 'peer_search_simplified'
....
node4.joinNetwork(bootstrap_port, "paul", "jane")
#test urls
urls = ["www.help.org", "www.ruby.org", "www.pluckit.io"]
node4.indexPage(urls, ["jane", "james"])
results = node4.search(["jane", "james"])
....
```


Sample Usage with Test Filesin Terminal
----------------

Terminal 1:
```
$ ruby nodes.rb --boot "james" --port 8780
```
starts a node with node id: "james" and port no. 8780

Terminal 2:
```
$ ruby node1.rb --boot_port 8780
```
starts a node with node id: "jane" and port no. 8780

Terminal 3:
```
$ ruby node2.rb --boot_port 8780
```
initializes two nodes, with id "jhon" and "paul" respectively.
node: "jhon" does not listen in the network and therefore has dropped unexpectedly, whereas node paul sends an INDEX message and then performs a search request.
Search results from request are written to testfile.json
```
cat testfile.json
```

Terminal 4:
```
$ ruby nodes3.rb --boot_port 8780
```
starts a node with node id: "peter" and port no. 8780

Issues
-------------

- The hash function does not seem to function accordingly as the node is's generated are not of the order of 2^32 but rather dependant on the length of the input string to be hased
- The routing table seems to be repeating nodes. This is not a problem when routing as the program can handle this issue, but its not clean nevertheless.
