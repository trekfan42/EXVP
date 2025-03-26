extends VBoxContainer

@onready var til = %InTime
@onready var tol = %OutTime
@onready var videoLabel = %VideoName
@onready var settingsPanel = %AudioSettings
@onready var trimControl: Panel = %VideoTrimControl
@onready var waveform_drawer = %WaveformDrawer


var type = "audio"

var loaded = false

var title

var reset = null

var itemData = {
	"path": null,
	"startPoint": 0,
	"endPoint": null,
	"length": null,
	"mode": 0,
	"volume": 0,
	"muted": false
}

var tempSettings = {
	"startPoint": 0,
	"endPoint": null,
	"volume": 0,
	"muted": false
}

var id:
	set(value):
		id = value

var total

var preview: ImageTexture

var thread: Thread

var peaksData = []

func _ready():
	%Spinner.status = 1
	Signals.queueItem.connect(queue_check)
	videoLabel.text = "🔉 " + title + "." + itemData["path"].get_extension()
	%AudioSettings.hide()
	load_preview()
	
	%VolumeSlider.value = float(itemData["volume"])
	%VolumeEdit.text = str(float(itemData["volume"]))

var resource: AudioStream

func load_preview():
	var path
	path = itemData["path"]
	if path.get_extension() == "mp3":
		resource = AudioStreamMP3.load_from_file(path)
	if path.get_extension() == "wav":
		resource = AudioStreamWAV.load_from_file(path)
	
	waveform_drawer.audio_stream = resource
	
	waveform_drawer.connect("audio_processed", update_peaks_data)
	
	loaded_preview()

func update_peaks_data():
	peaksData = [
		waveform_drawer.min_peaks,
		waveform_drawer.max_peaks
	]
	%Loading.hide()
	%WaveformDrawer.show()
	%WaveformViewer.set_peak_data(peaksData[0],peaksData[1])

func loaded_preview():
	if !loaded and resource is AudioStream:
		itemData["length"] =  int(ceil(resource.get_length()))
		print("audio length: " + str(itemData["length"]))
		itemData["endPoint"] = itemData["length"]
		itemData["endPoint"] = itemData["length"]
		itemData["startPoint"] = 0
		tol.text = Utils.Secs_To_MMSS(itemData["length"])

	for k in tempSettings.keys():
		tempSettings[k] = itemData[k]

	trimControl.setup_controls()
	print("trim settings: ")
	print(trimControl.start_trim)


func queue_check(_type,_itemData):
	if Global.activeIndex == self.get_index():
		%SelectVideoButton.text = "✅"
	else:
		%SelectVideoButton.text = "🔳"

func _on_mode_toggle_button_up() -> void:
	if itemData["mode"] < 2:
		itemData["mode"] += 1
	elif itemData["mode"] == 2:
		itemData["mode"] = 0
	
	if itemData["mode"] == 0:
		%ModeToggle.icon = load("res://UI/Icons/loop off.png")
	elif itemData["mode"] == 1:
		%ModeToggle.icon = load("res://UI/Icons/loop on.png")
	elif itemData["mode"] == 2:
		%ModeToggle.icon = load("res://UI/Icons/auto on.png")


func _on_remove_video_button_button_up():
	if self.get_index() == Global.activeIndex:
		Global.activeIndex = null
		Global.activeItem = null
		Global.activeType = null
		Global.removeItem.emit(type)
	self.queue_free()


func _on_select_video_button_button_up():
	Global.activeIndex = self.get_index()
	Global.activeItem = self
	Global.activeType = type
	Signals.queueItem.emit(type,itemData)


func set_volume(dB):
	tempSettings["volume"] = dB
	if dB == -80:
		tempSettings["muted"] = true
	else:
		tempSettings["muted"] = false
	update_vol_icon()

func update_vol_icon():
	#🔊🔉🔇
	if tempSettings["volume"] > -10:
		%VolIcon.text = "🔊"
	elif tempSettings["volume"] == -80:
		%VolIcon.text = "🔇"
	else:
		%VolIcon.text = "🔉"


func _on_trim_in_button_up():
	til.text = Utils.Secs_To_MMSS(Global.app.playslider.value)
	tempSettings["startPoint"] = Global.app.playslider.value

	if tempSettings["startPoint"] != 0:
		%InTime.self_modulate = Color.GREEN
		%TrimInClear.visible = true
	else:
		%InTime.self_modulate = Color.WHITE
		%TrimInClear.visible = false

func _on_trim_out_button_up():
	til.text = Utils.Secs_To_MMSS(Global.app.playslider.value)
	tempSettings["endPoint"] = Global.app.playslider.value

	if tempSettings["endPoint"] != tempSettings["length"]:
		%OutTime.self_modulate = Color.RED
		%TrimOutClear.visible = true
	else:
		%OutTime.self_modulate = Color.WHITE
		%TrimOutClear.visible = false

func _on_volume_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				%VolumeSlider.value = float(0)
				set_volume(0)
				check_new_settings()

func _on_timer_timeout():
	_on_remove_video_button_button_up()


func _on_area_2d_area_entered(_area):
	print("turn red")
	%DeleteBorder.visible = true


func _on_area_2d_area_exited(_area):
	print("turn normal")
	if is_instance_valid(%DeleteBorder):
		%DeleteBorder.visible = false


func _on_trim_in_clear_button_up():
	tempSettings["startPoint"] = 0
	check_new_settings()

func _on_trim_out_clear_button_up():
	tempSettings["endPoint"] = itemData["length"]
	check_new_settings()

func _on_aspect_option_button_item_selected(index: int) -> void:
	tempSettings["crop"] = index
	check_new_settings()


func update_settings_controls():
	
	%VolumeSlider.value = itemData["volume"]
	%VolumeEdit.text = str(itemData["volume"])
	set_volume(itemData["volume"])
	
	til.text = Utils.Secs_To_MMSS(itemData["startPoint"])
	tol.text = Utils.Secs_To_MMSS(itemData["endPoint"])




func check_new_settings():
	var changed = false
	for k in tempSettings.keys():
		if itemData[k] != tempSettings[k]:
			changed = true
	if changed:
		%SaveSettings.show()
	else:
		%SaveSettings.hide()

func _on_save_settings_button_up() -> void:

	for k in tempSettings.keys():
		itemData[k] = tempSettings[k]
	print(itemData)
	%SaveSettings.hide()


func _on_toggle_settings_button_up() -> void:
	
	%AudioSettings.visible = !%AudioSettings.visible
	check_new_settings()
	if %AudioSettings.visible:
		self.custom_minimum_size.y = 270
		trimControl.setup_controls()
	else:
		self.custom_minimum_size.y = 120
	


func _on_volume_slider_value_changed(value: float) -> void:
	var dB = int(value)
	%VolumeEdit.text = str(dB)
	set_volume(dB)
	check_new_settings()

func _on_volume_edit_text_submitted(new_text: String) -> void:
	var dB
	if new_text == "0":
		print("set to 0")
		dB = 0
	elif int(new_text):
		print("new vol: " + str(int(new_text)))
		dB = int(new_text)
	else:
		print("new vol not int: " + str(int(new_text)))
		%VolumeEdit.text = str(itemData["volume"])
	
	if dB >= -80 or dB <= 20:
		%VolumeSlider.value = float(dB)
		set_volume(dB)
		check_new_settings()
	elif dB == 0:
		%VolumeEdit.text = str(itemData["volume"])
	else:
		%VolumeEdit.text = str(itemData["volume"])
	


func _on_drag_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Signals.deletePopup.emit(true)
				%Area2D.monitorable = true
				print("clicked " + title)
			if event.is_released():
				print("released " + title)
				if Global.deleteReady == true:
					Signals.deletePopup.emit(false)
					%Timer.start()
				else:
					Signals.deletePopup.emit(false)
					%Area2D.monitorable = false
					print("changed mind")
