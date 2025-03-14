extends TextureRect

var picPath
var id
var parent

var thread: Thread


func _ready():
	Signals.queueItem.connect(check_self)
	Signals.loadThumbs.connect(load_thumbs)

func check_self(_type,_pics):
	if parent == Signals.activeItem:
		$Button.disabled = false
	else:
		$Button.disabled = true

func load_thumbs():
	thread = Thread.new()
	thread.start(draw_thumbs)

func draw_thumbs():
	var pic = Image.load_from_file(picPath)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	call_deferred("image_loaded",imageTexture)

func image_loaded(imageTexture):
	texture = imageTexture
	thread.wait_to_finish()


func _on_button_button_up():
	if Signals.playIcon:
		Signals.setSlide.emit(self.get_index(),true)
		Signals.slideshowRunning = !Signals.slideshowRunning
	else:
		Signals.setSlide.emit(self.get_index(),false)
