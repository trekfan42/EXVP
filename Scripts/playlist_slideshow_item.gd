extends MarginContainer



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
	"fadeTime": 2.0,
	"fit": true,
	"crop": false,
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
	Signals.setCrop.connect(parse_crop)
	folderLabel.text = "🎞️ " + title
	%HoldTime.text = str(itemData["holdTime"])
	%FadeTime.text = str(itemData["fadeTime"])
	var exts = ["png","jpg"]
	var files = []
	files = DirAccess.get_files_at(itemData["folder"])
	for f in files:
		if f.get_extension() in exts:
			#itemData["pics"].append(itemData["folder"] + "\\" + f)
			load_thumb(itemData["folder"] + "\\" + f)
		
	#add_thumbs(itemData["pics"])


#func add_thumbs(pics):
	#thumbs.get_parent().visible = true
	#for p in pics:
		#load_thumb(p)
		#

func load_thumb(path):
	var iThumb = slideshowThumb.instantiate()
	iThumb.picPath = path
	iThumb.parent = self
	thumbs.add_child(iThumb)
	iThumb.load_thumbs()


func secondsToMMSS(seconds):
	var minutes = seconds / 60
	var remainingSeconds = int(seconds) % 60
	var outputFormat = "%02d:%02d"
	var output = outputFormat % [floor(minutes) , round(remainingSeconds)]
	return output

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

func parse_crop(index):
	if index == 1:
		Signals.updateSlideOptions.emit("fit",true)
		Signals.updateSlideOptions.emit("crop",false)
	if index == 2:
		Signals.updateSlideOptions.emit("fit",false)
		Signals.updateSlideOptions.emit("crop",false)
	if index == 3:
		Signals.updateSlideOptions.emit("crop",true)
		Signals.updateSlideOptions.emit("fit",true)

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
	itemData["pics"].shuffle()
	for p in itemData["pics"]:
		var newIndex = itemData["pics"].find(p)
		for t in thumbs.get_children():
			if t.picPath == p:
				thumbs.move_child(t,newIndex)
	if Global.activeItem == self: 
		Signals.shuffleSlides.emit()



func _on_hold_time_text_changed(new_text):
	if float(new_text) or float(new_text) == 0:
		if float(new_text) != 0:
			itemData["holdTime"] = float(new_text)
			Signals.updateSlideOptions.emit("holdTime",itemData["holdTime"])
		else:
			%HoldTime.text = str(itemData["holdTime"])

func _on_fade_time_text_changed(new_text):
	if float(new_text) or float(new_text) == 0:
		if float(new_text) != 0:
			itemData["fadeTime"] = float(new_text)
			Signals.updateSlideOptions.emit("fadeTime",itemData["fadeTime"])
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
