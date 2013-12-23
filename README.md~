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
 "jane" -----> bootstrap
 "john" -----> "jane"
 "peter" -----> "jhon"
 "paul" -----> "peter"

The above .rb files must be called on separate consoles as each node has to run on its own process since each node polls
and blocks for messages to be received.

Running each node on a separate console with the node<x>.rb files configureing the corresponding nodes tests the system,
by instanciating a node with specified ID and port number and are set to listen in their corresponding ports for incomming messages.
Additionally the one node is just joined and does not listen, i.e. acting as a node that has left the network,
and two other nodes send INDEX messages accross the network, the data in the index message is then used when sending a
SEARCH message on the network looking for some of the content indexed.

This simple test showed that the system was working according to the developed protocol. However one bug to note is that the routing table
may contain duplicates. (unfortunately I had no more time left to fix this).
