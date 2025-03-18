extends Panel

const NDI_OUTPUT_SCENE = preload("res://Scenes/ndi_output_scene.tscn")

var ndiNode

func _ready() -> void:
	%UIScaleEdit.text = str(Global.uiScale)
	Global.uiScale = float(%UIScaleEdit.text)
	Signals.changedBG.connect(_on_open_still_file_dialog_file_selected)
	_on_reset_bg_button_up()
	%ResetBG.hide()

func _on_settings_close_button_button_up() -> void:
	Global.app.toggle_options()

func _on_options_output_button_up() -> void:
	show_options("OutputSettings")

func _on_options_network_button_up() -> void:
	show_options("NetworkSettings")


func _on_options_advanced_button_up() -> void:
	show_options("AdvancedSettings")

func _on_help_button_up() -> void:
	show_options("InfoDocumentation")


func _on_about_button_up() -> void:
	show_options("InfoAbout")


func _on_registration_button_up() -> void:
	show_options("InfoRegistration")

func show_options(settings):
	for e in %SettingsOptions.get_children():
		if e.name == settings:
			e.show()
		else:
			e.hide()


func _on_option_button_item_selected(index: int) -> void:
	if index == 0:
		Global.playbackEngine = FFmpegVideoStream
	Signals.setPlaybackEngine.emit(Global.playbackEngine)


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
	if int(new_text):
		if Global.outputResolution.x != abs(int(new_text)):
			Global.outputResolution = Vector2i(abs(int(new_text)) , Global.outputResolution.y)
			%ResWidth.text = str(Global.outputResolution.x)
	else:
		%ResWidth.text = str(Global.outputResolution.x)


func _on_res_height_text_submitted(new_text: String) -> void:
	if int(new_text):
		if Global.outputResolution.y != abs(int(new_text)):
			Global.outputResolution = Vector2i(Global.outputResolution.x , abs(int(new_text)))
			%ResHeight.text = str(Global.outputResolution.y)
	else:
		%ResHeight.text = str(Global.outputResolution.y)



func _on_ui_scale_edit_text_submitted(new_text: String) -> void:
	if float(new_text): 
		Global.uiScale = float(new_text)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_timer_timeout() -> void:
	%UIScaleEdit.self_modulate = Color.WHITE


func _on_scale_up_button_button_up() -> void:
	if float(%UIScaleEdit.text):
		if Global.uiScale < 1.4:
			Global.uiScale += 0.1
			%UIScaleEdit.text = str(Global.uiScale)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_scale_down_button_button_up() -> void:
	if float(%UIScaleEdit.text):
		if Global.uiScale > 0.6:
			Global.uiScale -= 0.1
			%UIScaleEdit.text = str(Global.uiScale)
	else:
		%UIScaleEdit.self_modulate = Color.RED


func _on_res_height_focus_exited() -> void:
	if int(%ResHeight.text):
		if Global.outputResolution.y != abs(int(%ResHeight.text)):
			Global.outputResolution = Vector2i(Global.outputResolution.x , abs(int(%ResHeight.text)))
			%ResHeight.text = str(Global.outputResolution.y)
	else:
		%ResHeight.text = str(Global.outputResolution.y)


func _on_res_width_focus_exited() -> void:
	if int(%ResWidth.text):
		if Global.outputResolution.x != abs(int(%ResWidth.text)):
			Global.outputResolution = Vector2i(abs(int(%ResWidth.text)) , Global.outputResolution.y)
			%ResWidth.text = str(Global.outputResolution.x)
	else:
		%ResWidth.text = str(Global.outputResolution.x)


func _on_fps_text_submitted(new_text: String) -> void:
	Global.outputFPS = int(new_text)


func _on_fps_focus_exited() -> void:
	Global.outputFPS = int(%FPS.text)


func _on_open_still_file_dialog_file_selected(path: String) -> void:
	var pic = Image.load_from_file(path)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	%BGPic.texture = imageTexture
	%ResetBG.show()

func _on_bg_image_load_button_up() -> void:
	%LoadBGImageDialog.show()


func _on_reset_bg_button_up() -> void:
	_on_open_still_file_dialog_file_selected(Global.defaultBG)
	%ResetBG.hide()


func _on_blur_color_picker_color_changed(color: Color) -> void:
	%BGBlur.material.set_shader_parameter("color_over", color)


func _on_blur_strength_slider_value_changed(value: float) -> void:
	%BGBlur.material.set_shader_parameter("blur_amount", value)
	%BlurStrengthEdit.text = str(value)

func _on_blur_strength_edit_text_submitted(new_text: String) -> void:
	if int(new_text):
		%BGBlur.material.set_shader_parameter("blur_amount", int(new_text))
		%BlurStrengthSlider.value = float(new_text)
	else:
		%BlurStrengthEdit.text = %BGBlur.material.get_shader_parameter("blur_amount")


func _on_blur_strength_edit_focus_exited() -> void:
	if int(%BlurStrengthEdit.text):
		%BGBlur.material.set_shader_parameter("blur_amount", int(%BlurStrengthEdit.text))
		%BlurStrengthSlider.value = float(%BlurStrengthEdit.text)
	else:
		%BlurStrengthEdit.text = %BGBlur.material.get_shader_parameter("blur_amount")


func _on_blur_color_mix_slider_value_changed(value: float) -> void:
	%BGBlur.material.set_shader_parameter("mix_amount", value)
	%BlurColorMixEdit.text = str(value)

func _on_blur_color_mix_edit_text_submitted(new_text: String) -> void:
	if int(new_text):
		%BGBlur.material.set_shader_parameter("mix_amount", int(new_text))
		%BlurColorMixSlider.value = float(new_text)
	else:
		%BlurColorMixEdit.text = %BGBlur.material.get_shader_parameter("mix_amount")


func _on_blur_color_mix_edit_focus_exited() -> void:
	if int(%BlurColorMixEdit.text):
		%BGBlur.material.set_shader_parameter("mix_amount", int(%BlurColorMixEdit.text))
		%BlurColorMixSlider.value = float(%BlurColorMixEdit.text)
	else:
		%BlurColorMixEdit.text = %BGBlur.material.get_shader_parameter("mix_amount")
