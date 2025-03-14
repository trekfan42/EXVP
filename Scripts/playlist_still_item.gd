extends MarginContainer

@onready var imageLabel = %ImageName
@onready var thumb = %Thumb

var type = "still"

var title

# [pics,holdTime,fadeTime,crop,bgColor]
var itemData = {
	"path": null,
	"fit": true,
	"crop": false,
	"bgColor": Color(0,0,0),
}

var id:
	set(value):
		id = value
var total


func _ready():
	Signals.queueItem.connect(queue_check)
	Signals.setCrop.connect(parse_crop)
	Signals.Option.connect(still_options)
	if title.length() > 20:
		imageLabel.text = "🖼️ " + title.substr(0,20) + "..."
	else:
		imageLabel.text = "🖼️ " + title
	load_thumb(itemData["path"])


func load_thumb(picPath):
	var pic = Image.load_from_file(picPath)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	thumb.texture = imageTexture


func queue_check(_type , _itemData):
	if Signals.activeIndex == self.get_index():
		%SelectVideoButton.text = "✅"
	else:
		%SelectVideoButton.text = "🔳"

func parse_crop(index):
	if Signals.activeItem == self:
		if index == 1:
			itemData["fit"] = true
			itemData["crop"] = false
			Signals.updateSlideOptions.emit("fit",true)
			Signals.updateSlideOptions.emit("crop",false)
		if index == 2:
			itemData["fit"] = false
			itemData["crop"] = false
			Signals.updateSlideOptions.emit("fit",false)
			Signals.updateSlideOptions.emit("crop",false)
		if index == 3:
			itemData["fit"] = true
			itemData["crop"] = true
			Signals.updateSlideOptions.emit("crop",true)
			Signals.updateSlideOptions.emit("fit",true)

func _on_remove_video_button_button_up():
	if self.get_index() == Signals.activeIndex:
		Signals.activeIndex = null
		Signals.activeItem = null
		Signals.activeType = null
		Signals.removeItem.emit(type)
	self.queue_free()

func _on_select_video_button_button_up():
	Signals.slideshow.emit(self)
	Signals.activeIndex = self.get_index()
	Signals.activeItem = self
	Signals.activeType = type
	
	var picture = thumb.texture
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
				if Signals.deleteReady == true:
					Signals.deletePopup.emit(false)
					%Timer.start()
				else:
					Signals.deletePopup.emit(false)
					%Area2D.monitorable = false
					print("changed mind")

func _on_timer_timeout():
	_on_remove_video_button_button_up()


func _on_area_2d_area_entered(area):
	print("turn red")
	%DeleteBorder.visible = true


func _on_area_2d_area_exited(area):
	print("turn normal")
	if is_instance_valid(%DeleteBorder):
		%DeleteBorder.visible = false
