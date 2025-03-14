extends Panel

const NDI_OUTPUT_SCENE = preload("res://Scenes/ndi_output_scene.tscn")

const APP_BG = preload("res://AppBG.jpg")

var ndiNode

func _ready() -> void:
	%UIScaleEdit.text = str(Signals.uiScale)
	Signals.uiScale = float(%UIScaleEdit.text)
	%ResetBG.hide()

func _on_settings_close_button_button_up() -> void:
	self.get_parent().hide()
	self.hide()

func _on_options_output_button_up() -> void:
	show_options("OutputSettings")

func _on_options_network_button_up() -> void:
	show_options("NetworkSettings")


func _on_options_advanced_button_up() -> void:
	show_options("AdvancedSettings")

func show_options(settings):
	for e in %SettingsOptions.get_children():
		if e.name == settings:
			e.show()
		else:
			e.hide()


func _on_option_button_item_selected(index: int) -> void:
	if index == 0:
		Signals.playbackEngine = FFmpegVideoStream
	elif index == 1:
		Signals.playbackEngine = VideoStreamVLC
	Signals.setPlaybackEngine.emit(Signals.playbackEngine)


func _on_ndi_toggle_button_up() -> void:
	if !ndiNode:
		var ndiOutput = NDI_OUTPUT_SCENE.instantiate()
		if ndiOutput.name != %NDIOutputName.text:
			ndiOutput.name = %NDIOutputName.text
			ndiNode = ndiOutput
		%VideoSubViewport.add_child(ndiOutput)
		%NDIToggle.text = " ✅" #✅🔳
		%NDIOutputName.editable = false
	else:
		%NDIToggle.text = " 🔳" #✅🔳
		ndiNode.queue_free()
		%NDIOutputName.editable = true


func _on_res_width_text_submitted(new_text: String) -> void:
	Signals.outputResolution.x = int(new_text)


func _on_res_height_text_submitted(new_text: String) -> void:
	Signals.outputResolution.y = int(new_text)



func _on_ui_scale_edit_text_submitted(new_text: String) -> void:
	if float(new_text): 
		Signals.uiScale = float(new_text)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_timer_timeout() -> void:
	%UIScaleEdit.self_modulate = Color.WHITE


func _on_scale_up_button_button_up() -> void:
	if float(%UIScaleEdit.text):
		if Signals.uiScale < 1.4:
			Signals.uiScale += 0.1
			%UIScaleEdit.text = str(Signals.uiScale)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_scale_down_button_button_up() -> void:
	if float(%UIScaleEdit.text):
		if Signals.uiScale > 0.6:
			Signals.uiScale -= 0.1
			%UIScaleEdit.text = str(Signals.uiScale)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_res_height_focus_exited() -> void:
	Signals.outputResolution.y = int(%ResHeight.text)


func _on_res_width_focus_exited() -> void:
	Signals.outputResolution.y = int(%ResWidth.text)


func _on_fps_text_submitted(new_text: String) -> void:
	Signals.outputFPS = int(new_text)


func _on_fps_focus_exited() -> void:
	Signals.outputFPS = int(%FPS.text)


func _on_open_still_file_dialog_file_selected(path: String) -> void:
	var pic = Image.load_from_file(path)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	%BGPic.texture = imageTexture
	%ResetBG.show()

func _on_bg_image_load_button_up() -> void:
	%LoadBGImageDialog.show()


func _on_reset_bg_button_up() -> void:
	%BGPic.texture = APP_BG
	%ResetBG.hide()
