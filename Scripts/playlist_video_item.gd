extends VBoxContainer

@onready var til = %InTime
@onready var tol = %OutTime
@onready var videoLabel = %VideoName
@onready var thumbAspect = %AspectRatioContainer
@onready var thumbPlayer = %VideoLoaderPlayer

@onready var trimControl: Panel = %VideoTrimControl


var type = "video"

var title
var aspect
var crop

var reset = null

# [path,startPoint,endPoint,length,width,height,volume] 
var itemData = {
	"path": null,
	"startPoint": 0,
	"endPoint": null,
	"length": null,
	"width": null,
	"height": null,
	"volume": 0,
	"muted": false,
	"crop": 0
}

var tempSettings = {
	"startPoint": 0,
	"endPoint": null,
	"volume": 0,
	"muted": false,
	"crop": 0
}

var id:
	set(value):
		id = value

var total

var frame

var thread: Thread

func _ready():
	%LoadingSprite.play("default")
	thumbPlayer.visible = false
	Signals.queueItem.connect(queue_check)
	videoLabel.text = "🎬 " + title + "." + itemData["path"].get_extension()
	%VideoSettings.hide()
	load_thumb()
	
	for k in tempSettings.keys():
		tempSettings[k] = itemData[k]

func load_thumb():
	thread = Thread.new()
	thread.start(load_video)

func load_video():
	var resource := FFmpegVideoStream.new()
	resource.file = itemData["path"]
	thumbPlayer.stream = load(itemData["path"])
	itemData["length"] = int(ceil(thumbPlayer.get_stream_length()))
	print("video length: ", itemData["length"])
	itemData["height"] = thumbPlayer.get_video_texture().get_size().y
	itemData["width"] = thumbPlayer.get_video_texture().get_size().x
	print("video size x: ", itemData["width"])
	print("video size y: ", itemData["height"])
	thumbAspect.ratio = itemData["width"] / itemData["height"]
	thumbPlayer.play()
	thumbPlayer.volume_db = -80
	thumbPlayer.set_stream_position(itemData["length"] / 2)
	var stillFrame = thumbPlayer.get_stream_position()
	tol.text = Utils.Secs_To_MMSS(itemData["length"])
	itemData["endPoint"] = itemData["length"]
	
	
	
	
	
	call_deferred("loaded_thumb")
	trimControl.setup_controls()
	return stillFrame

func loaded_thumb():
	frame = thread.wait_to_finish()


func _process(_delta):
	if thumbPlayer.paused == false and frame:
		if thumbPlayer.get_stream_position() > frame + 0.5:
			%LoadingSprite.stop()
			%Loading.hide()
			thumbAspect.visible = true
			thumbPlayer.visible = true
			thumbPlayer.paused = true


func queue_check(_type,_itemData):
	if Global.activeIndex == self.get_index():
		%SelectVideoButton.text = "✅"
	else:
		%SelectVideoButton.text = "🔳"


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

func _on_move_down_button_button_up():
	var index = self.get_index() + 1
	Signals.sort.emit(self,index)


func _on_move_up_button_button_up():
	var index = self.get_index() - 1
	Signals.sort.emit(self,index)

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
	%AspectOptionButton.selected = itemData["crop"]
	
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
	print("Original Video Settings: ")
	print(itemData)
	for k in tempSettings.keys():
		itemData[k] = tempSettings[k]
	print("New Video Settings: ")
	print(itemData)
	%SaveSettings.hide()


func _on_toggle_settings_button_up() -> void:
	%VideoSettings.visible = !%VideoSettings.visible
	if %VideoSettings.visible:
		self.custom_minimum_size.y = 270
	else:
		self.custom_minimum_size.y = 120
	check_new_settings()


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
