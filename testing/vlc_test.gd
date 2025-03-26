extends Control


func _on_native_file_dialog_file_selected(path: String) -> void:
	var resource = VideoStreamVLC.new()
	resource.file = path
	$VideoStreamPlayer.stream = resource
	$VideoStreamPlayer.play()
	if $VideoStreamPlayer.stream is VideoStreamVLC:
		print("success")
		print($VideoStreamPlayer.stream.get_stream_length())
	else:
		print("fail")


func _on_button_button_up() -> void:
	$NativeFileDialog.show()
