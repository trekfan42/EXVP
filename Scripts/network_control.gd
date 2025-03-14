extends Node



var http
var listening = false

# HTTP TCP COMMANDS
var command:
	set(value):
		print(command)
		command = value
		run_command(value)

func _on_tcp_listen_button_button_up():
	listening = !listening
	toggle_listener()

func toggle_listener():
	var address = %ServerAddress.text
	if listening:
		%TCPListenButton.text = " ✅"
		Signals.tcpStatus.emit(true,address)
	else:
		%TCPListenButton.text = " 🔳"
		Signals.tcpStatus.emit(false,address)

func run_command(rxCommand):
	if listening:
		if rxCommand == "play":
			Signals.pauseToggle.emit()
		if rxCommand == "next":
			Signals.app.go_to_video(rxCommand)
		if rxCommand == "previous":
			Signals.app.go_to_video(rxCommand)
		if rxCommand == "SetIn":
			Signals.app.trim_point(rxCommand)
		if rxCommand == "SetOut":
			Signals.app.trim_point(rxCommand)
		if rxCommand == "VolUp":
			Signals.app.adj_vol(rxCommand)
		if rxCommand == "VolDown":
			Signals.app.adj_vol(rxCommand)

var http1Active = false
var http2Active = false

func update_time(timeElapsed,timeLeft):
	var companion = %CompanionAddress.text
	var command1 = "http://" + companion + "/set/custom-variable/EXVP_In?value=" + str(timeElapsed)
	var command2 = "http://" + companion + "/set/custom-variable/EXVP_Out?value=" + str(timeLeft)
	
	if !http1Active:
		%HTTPRequest1.request(command1)
		http1Active = true
	if !http2Active:
		%HTTPRequest2.request(command2)
		http2Active = true

func _on_http_request_1_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		%HTTPRequest1.cancel_request()
		http1Active = false

func _on_http_request_2_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		%HTTPRequest2.cancel_request()
		http2Active = false
