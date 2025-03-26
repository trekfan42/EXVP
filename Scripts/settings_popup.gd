extends Panel

const NDI_OUTPUT_SCENE = preload("res://Scenes/ndi_output_scene.tscn")

var ndiNode

func _ready() -> void:
	%UIScaleEdit.text = str(Global.uiScale)
	Global.uiScale = float(%UIScaleEdit.text)
	Signals.changedBG.connect(_on_open_still_file_dialog_file_selected)
	_on_reset_bg_button_up()
	%ResetBG.hide()
	%Version.text = "v " + Global.version
	detect_ndi()



func detect_ndi():
	if DirAccess.dir_exists_absolute("C://Program Files/NDI/NDI 6 Runtime/v6"):
		print("NDI Installation found")
		%NDIDetection.hide()
		%NDISettings.show()
	else:
		%NDIDetection.show()
		%NDISettings.hide()

func _on_ndi_download_button_up() -> void:
	OS.shell_open("http://ndi.link/NDIRedistV6")

func _on_ndi_download_2_button_up() -> void:
	OS.shell_open("https://ndi.video/tools/")


func _on_ndi_monitor_button_up() -> void:
	if DirAccess.dir_exists_absolute("C://Program Files/NDI/NDI 6 Tools/Studio Monitor"):
		find_and_run_exe("C:/Program Files/NDI", "StudioMonitor")
	else:
		_on_ndi_download_2_button_up()


func find_and_run_exe(directory: String, search_string: String):
	# Get the File and Directory access API
	var dir := DirAccess.open(directory)
	if dir == null:
		print("Failed to open directory: ", directory)
		return
	
	# Scan directory
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := directory + "/" + file_name # Correct path concatenation
		
		# Check if it's a directory and recursively search inside
		if dir.current_is_dir():
			find_and_run_exe(full_path, search_string)
		else:
			# Check if it's an executable and contains the search string
			if file_name.ends_with(".exe") and search_string in file_name:
				print("Found executable: ", full_path)
				OS.create_process(full_path, [])
				return # Exit after running the first match
		
		file_name = dir.get_next()





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
		%NDIToggle.text = "✅" #✅🔳
		%NDIOutputName.editable = false
	else:
		%NDIToggle.text = "🔳" #✅🔳
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
	if float(new_text):
		if float(new_text) <= 60 and float(new_text) >= 20:
			Global.outputFPS = float(new_text)
	else:
		%FPS.text = str(float(Global.outputFPS))


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
	%BGPic.texture = Global.defaultBG
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


func _on_ambient_mode_button_up() -> void:
	if %BGShader.visible:
		%AmbientMode.text = "🔳" #✅🔳
		%BGShader.hide()
		%BGImageSettings.show()
	else:
		%AmbientMode.text = "✅" #✅🔳
		%BGShader.show()
		%BGImageSettings.hide()
