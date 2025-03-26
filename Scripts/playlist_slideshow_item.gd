extends VBoxContainer



@onready var folderLabel = %FolderName
@onready var thumbs = %Thumbs



var slideshowThumb = preload("res://Scenes/slideshow_thumb.tscn")

var type = "slideshow"

var loaded = false

var title

# [pics,holdTime,fadeTime,crop,bgColor]
@export var itemData : Dictionary  = {
	"folder": null,
	"pics": [],
	"holdTime": 4.0,
	"fadeTime": 1.5,
	"mode": 0,
	"crop": 3,
	"bgColor": Color(0,0,0),
}

@export var tempSettings : Dictionary  = {
	"pics": [],
	"holdTime": 4.0,
	"fadeTime": 1.5,
	"crop": 3,
	"bgColor": Color(0,0,0),
}

var id:
	set(value):
		id = value
var total = 0

var thread: Thread

func _ready():
	Signals.queueItem.connect(queue_check)
	Signals.Option.connect(slideshow_options)
	Signals.slide.connect(scroll_to_thumb)
	folderLabel.text = "🎞️ " + title
	%HoldTime.text = str(itemData["holdTime"])
	%FadeTime.text = str(itemData["fadeTime"])
	%AspectOptionButton.selected = itemData["crop"]
	
	%SlideshowSettings.hide()
	var files = []
	files = DirAccess.get_files_at(itemData["folder"])
	for f in files:
		if f.get_extension() in Global.picExts:
			#itemData["pics"].append(itemData["folder"] + "\\" + f)
			load_thumb(itemData["folder"] + "\\" + f)
	
	if loaded:
		for t in thumbs.get_children():
			var newPos = 0
			for p in itemData["pics"]:
				if t.title == p[0]:
					p[1] = int(p[1])
					newPos = int(p[1])
			
			thumbs.move_child(t,newPos)
			print("moving pic from: " + str(t.get_index()) + " to: " + str(newPos) )


	for k in tempSettings.keys():
		tempSettings[k] = itemData[k]

func load_thumb(path):
	var iThumb = slideshowThumb.instantiate()
	iThumb.picPath = path
	iThumb.title = path.get_file().get_basename()
	iThumb.parent = self
	thumbs.add_child(iThumb)
	iThumb.load_thumbs()
	
	iThumb.id = iThumb.get_index()
	var picInfo = [ iThumb.title , iThumb.id ]
	if !loaded:
		itemData["pics"].append( picInfo )



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
				px += p.get_size().x + 10 
		var tween = get_tree().create_tween()
		tween.tween_property(%ThumbsScroll, "scroll_horizontal", px, 0.25)

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
	Signals.slideshow.emit(self)
	Global.activeIndex = self.get_index()
	Global.activeItem = self
	Global.activeType = type
	var grabbedPics = get_thumb_pics()
	Signals.queueItem.emit(type,grabbedPics)


func get_thumb_pics():
	var picTextures = []
	for p in thumbs.get_children():
		picTextures.append(p.texture)
	return picTextures



func slideshow_options(status):
	%OptionButtons.visible = status
	thumbs.visible = !status
	%RemoveVideoButton.visible = status



func _on_shuffle_button_button_up():
	print("Shuffling...")

	tempSettings["pics"].shuffle()
	var picCount = tempSettings["pics"].size()
	for p in picCount:
		tempSettings["pics"][p][1] = p
	
	for p in tempSettings["pics"]:
		for t in thumbs.get_children():
			if t.title == p[0]:
				thumbs.move_child(t,p[1])

	itemData["pics"] = tempSettings["pics"]



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
			if event.is_released():
				if Global.deleteReady == true:
					Signals.deletePopup.emit(false)
					%Timer.start()
				else:
					Signals.deletePopup.emit(false)
					%Area2D.monitorable = false

func _on_timer_timeout():
	_on_remove_video_button_button_up()


func _on_area_2d_area_entered(_area):
	%DeleteBorder.visible = true


func _on_area_2d_area_exited(_area):
	if is_instance_valid(%DeleteBorder):
		%DeleteBorder.visible = false


func _on_save_settings_button_up() -> void:
	for k in tempSettings.keys():
		itemData[k] = tempSettings[k]
	%SaveSettings.hide()


func _on_toggle_settings_button_up() -> void:
	%SlideshowSettings.visible = !%SlideshowSettings.visible
	if %SlideshowSettings.visible:
		self.custom_minimum_size.y = 220
	else:
		self.custom_minimum_size.y = 140
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


func _on_thumbs_reordered(from: int, to: int) -> void:
	print(str(from) + " to " + str(to))
	for t in thumbs.get_children():
		if t.id == from:
			t.id = to
		for p in itemData["pics"]:
			if t.title == p[0]:
				p[1] = t.get_index()
	itemData["pics"].sort_custom(func(a, b): return a[1] < b[1])
	scroll_to_thumb(to)
