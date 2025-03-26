extends VBoxContainer

@onready var imageLabel = %ImageName
@onready var thumb = %Thumb

var type = "still"

var loaded = false

var title

# [pics,holdTime,fadeTime,crop,bgColor]
var itemData = {
	"path": null,
	"mode": 0, #Always 0 for stills
	"crop": 3,
	"bgColor": Color(0,0,0),
}


var tempSettings = {
	"crop": 3,
	"bgColor": Color(0,0,0),
}

var id:
	set(value):
		id = value
var total


func _ready():
	Signals.queueItem.connect(queue_check)
	Signals.Option.connect(still_options)
	%StillSettings.hide()
	%AspectOptionButton.selected = itemData["crop"]
	
	if title.length() > 20:
		imageLabel.text = "🖼️ " + title.substr(0,20) + "..."
	else:
		imageLabel.text = "🖼️ " + title
	load_thumb(itemData["path"])
	
	for k in tempSettings.keys():
		tempSettings[k] = itemData[k]


func load_thumb(picPath):
	var pic = Image.load_from_file(picPath)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	thumb.texture = imageTexture
	
	


func queue_check(_type , _itemData):
	if Global.activeIndex == self.get_index():
		%SelectVideoButton.text = "✅"
		Signals.setCrop.emit(itemData["crop"])
	else:
		%SelectVideoButton.text = "🔳"



func _on_remove_video_button_button_up():
	if self.get_index() == Global.activeIndex:
		Global.activeIndex = null
		Global.activeItem = null
		Global.activeType = null
		Signals.removeItem.emit(type)
	self.queue_free()

func _on_select_video_button_button_up():
	Signals.slideshow.emit(self)
	Global.activeIndex = self.get_index()
	Global.activeItem = self
	Global.activeType = type
	Signals.queueItem.emit(type,itemData)

func still_options(status):
	%RemoveVideoButton.visible = status

func _on_gui_input(event):	
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

func _on_timer_timeout():
	_on_remove_video_button_button_up()


func _on_area_2d_area_entered(_area):
	print("turn red")
	%DeleteBorder.visible = true


func _on_area_2d_area_exited(_area):
	print("turn normal")
	if is_instance_valid(%DeleteBorder):
		%DeleteBorder.visible = false


func _on_aspect_option_button_item_selected(index: int) -> void:
	tempSettings["crop"] = index
	check_new_settings()


func _on_save_settings_button_up() -> void:
	print("Original Still Settings: ")
	print(itemData)
	for k in tempSettings.keys():
		itemData[k] = tempSettings[k]
	print("New Still Settings: ")
	print(itemData)
	%SaveSettings.hide()


func _on_toggle_settings_button_up() -> void:
	%StillSettings.visible = !%StillSettings.visible
	if %StillSettings.visible:
		self.custom_minimum_size.y = 200
	else:
		self.custom_minimum_size.y = 120
	check_new_settings()


func check_new_settings():
	var changed = false
	for k in tempSettings.keys():
		if itemData[k] != tempSettings[k]:
			changed = true
	if changed:
		%SaveSettings.show()
	else:
		%SaveSettings.hide()
