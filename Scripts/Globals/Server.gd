extends Node

var server = TCPServer.new()
var peer = null


func _ready():
	Signals.tcpStatus.connect(listening_toggle)


func _process(_delta):
	# Check for new connections
	check_connection()

	# Ensure peer is still valid
	if peer:
		peer.poll()  # Make sure the peer updates its state

		# Check if peer is still connected
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if peer.get_available_bytes() > 0:
				var data = peer.get_string(peer.get_available_bytes()).strip_edges()
				print("Received:", data)
				Global.app.networkControl.command = data
		else:
			print("Peer disconnected.")
			peer = null  # Reset peer


func listening_toggle(status, address):
	if status == true:
		print("Starting TCP Server")
		var listeningAddress = address.get_slice(":", 0)
		var listeningPort = int(address.get_slice(":", 1))
		print(listeningAddress)
		print(listeningPort)
		server.listen(listeningPort, listeningAddress)
	else:
		print("Stopping TCP Server")
		server.stop()


func check_connection():
	if server.is_connection_available():
		var new_peer = server.take_connection()
		if new_peer == null:
			print("No valid peer connection.")
			return

		# Check if new peer is actually connected
		if new_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			print("Connected peer:", new_peer)
			peer = new_peer  # Store the peer
		else:
			print("New peer connection failed.")
