extends Node

var server = TCPServer.new()
var message
var peer


@onready var app = get_tree().get_root().get_child(2)

func _ready():
	Signals.tcpStatus.connect(listening_toggle)

func listening_toggle(status,address):
	if status == true:
		print("starting TCP Server")
		var listeningAddress = address.get_slice(":", 0)
		var listeningPort = int(address.get_slice(":", 1))
		print(listeningAddress)
		print(listeningPort)
		server.listen(listeningPort,listeningAddress)
	else:
		print("stopping TCP Server")
		server.stop()

func check_connection():
	if server.is_connection_available():
		peer = server.take_connection()
		var data = peer.get_string(peer.get_available_bytes())
		var parse = data.get_slice("$",1)
		app.command = parse
		
#		var response := "HTTP/1.1 200 OK\nContent-Type: text/html; charset=utf-8\n\nHi There"
#		peer.put_data(response.to_utf8_buffer())
