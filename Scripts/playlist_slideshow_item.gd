extends VBoxContainer



@onready var folderLabel = %FolderName
@onready var thumbs = %Thumbs



var slideshowThumb = preload("res://Scenes/slideshow_thumb.tscn")

var type = "slideshow"

var title

# [pics,holdTime,fadeTime,crop,bgColor]
var itemData = {
	"folder": null,
	"pics": [],
	"holdTime": 4.0,
	"fadeTime": 1.5,
	"crop": 1,
	"bgColor": Color(0,0,0),
}

var tempSettings = {
	"pics": [],
	"holdTime": 4.0,
	"fadeTime": 1.5,
	"crop": 1,
	"bgColor": Color(0,0,0),
}

var id:
	set(value):
		id = value
var total

var thread: Thread

func _ready():
	Signals.queueItem.connect(queue_check)
	Signals.Option.connect(slideshow_options)
	Signals.slide.connect(scroll_to_thumb)
	folderLabel.text = "🎞️ " + title
	%HoldTime.text = str(itemData["holdTime"])
	%FadeTime.text = str(itemData["fadeTime"])
	%SlideshowSettings.hide()
	var exts = ["png","jpg"]
	var files = []
	files = DirAccess.get_files_at(itemData["folder"])
	for f in files:
		if f.get_extension() in exts:
			#itemData["pics"].append(itemData["folder"] + "\\" + f)
			load_thumb(itemData["folder"] + "\\" + f)
	
	for k in tempSettings.keys():
		tempSettings[k] = itemData[k]

func load_thumb(path):
	var iThumb = slideshowThumb.instantiate()
	iThumb.picPath = path
	iThumb.parent = self
	thumbs.add_child(iThumb)
	iThumb.load_thumbs()



func queue_check(_type , _itemData):
	
	if Global.activeIndex == self.get_index():
		%SelectVideoButton.text = "✅"
	else:
		%SelectVideoButton.text = "🔳"

func scroll_to_thumb(idDest):
	if self == Global.activeItem:
		var px = 0
		for p in thumbs.get_children():
			if p.get_index() < idDest:
				px += p.get_size().x
		var tween = get_tree().create_tween()
		tween.tween_property(%ThumbsScroll, "scroll_horizontal", px, 0.25)



func _on_remove_video_button_button_up():
	if self.get_index() == Global.activeIndex:
		Global.activeIndex = null
		Global.activeItem = null
		Global.activeType = null
		Global.removeItem.emit(type)
	self.queue_free()
	


func _on_select_video_button_button_up():
	print("crop check 1: " + str(itemData["crop"]))
	Signals.slideshow.emit(self)
	Global.activeIndex = self.get_index()
	Global.activeItem = self
	Global.activeType = type
	var grabbedPics = get_thumb_pics()
	print("crop check 2: " + str(itemData["crop"]))
	Signals.queueItem.emit(type,grabbedPics)
	print("crop check 3: " + str(itemData["crop"]))
	
	

func get_thumb_pics():
	var pics = []
	for p in thumbs.get_children():
		pics.append(p.texture)
	return pics



func _on_move_down_button_button_up():
	var index = self.get_index() + 1
	Signals.sort.emit(self,index)


func _on_move_up_button_button_up():
	var index = self.get_index() - 1
	Signals.sort.emit(self,index)

func slideshow_options(status):
	%OptionButtons.visible = status
	thumbs.visible = !status
	%RemoveVideoButton.visible = status

func _on_shuffle_button_button_up():
	tempSettings["pics"].shuffle()
	for p in tempSettings["pics"]:
		var newIndex = itemData["pics"].find(p)
		for t in thumbs.get_children():
			if t.picPath == p:
				thumbs.move_child(t,newIndex)
	check_new_settings()



func _on_hold_time_text_changed(new_text):
	if float(new_text) or int(new_text):
		if float(new_text) != 0.0 or int(new_text) != 0:
			tempSettings["holdTime"] = abs(float(new_text))
			check_new_settings()
			#Signals.updateSlideOptions.emit("holdTime",itemData["holdTime"])
		else:
			%HoldTime.text = str(itemData["holdTime"])

func _on_fade_time_text_changed(new_text):
	if float(new_text) or int(new_text):
		if float(new_text) != 0.0 or int(new_text) != 0:
			tempSettings["fadeTime"] = abs(float(new_text))
			check_new_settings()
			#Signals.updateSlideOptions.emit("fadeTime",itemData["fadeTime"])
		else:
			%FadeTime.text = str(itemData["fadeTime"])


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


func _on_save_settings_button_up() -> void:
	print("Original Still Settings: ")
	print(itemData)
	for k in tempSettings.keys():
		itemData[k] = tempSettings[k]
	print("New Still Settings: ")
	print(itemData)
	%SaveSettings.hide()


func _on_toggle_settings_button_up() -> void:
	%SlideshowSettings.visible = !%SlideshowSettings.visible
	if %SlideshowSettings.visible:
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


func _on_aspect_option_button_item_selected(index: int) -> void:
	tempSettings["crop"] = index
	check_new_settings()
