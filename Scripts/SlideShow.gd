extends Node

@onready var holdTimer = $HoldTimer

var current = null
var slide = preload("res://Scenes/slideshow_pic.tscn")
var still = preload("res://Scenes/Still_Image.tscn")
var waiting = false

var tempCrop = null

var slideshowNode

func _ready():
	Signals.startSlides.connect(start_slides)
	Signals.pauseSlides.connect(stop_timers)
	Signals.setSlide.connect(go_to_slide)
	Signals.updateSlideCrop.connect(update_crop)
	Signals.slideshow.connect(load_node)
	


func load_node(node):
	tempCrop = null
	slideshowNode = node
	self.visible = true
	print("slideshow node: " + str(node))

func load_still(stillData):
	tempCrop = null
	var iStill = still.instantiate()
	iStill.picPath = stillData["path"]
	iStill.parse_crop(stillData["crop"])
	self.add_child(iStill)


func update_crop(index):
	tempCrop = index
	for s in self.get_children():
		if s.name != "HoldTimer":
			s.parse_crop(tempCrop)

func start_slides(sliderValue):
	if sliderValue == 1:
		go_to_slide(0,false)
	else:
		for s in self.get_children():
			if s.name != "HoldTimer":
				if s.self_modulate != Color.WHITE:
					s.fade_in(slideshowNode.itemData["fadeTime"])
				else:
					s.fade_in_finished()


func clear_slideshow():
	for p in self.get_children():
		if p.name != "HoldTimer":
			p.queue_free()
	Global.slideshowRunning = false

func go_to_slide(id,quiet):
	for s in self.get_children():
		if s.name != "HoldTimer":
			s.fade_out(slideshowNode.itemData["fadeTime"])

	load_slide(id,quiet)

func load_slide(id,quiet):
	Global.slideshowRunning = true
	Signals.slide.emit(id)
	Global.activeSlide = id
	var iSlide = slide.instantiate()
	iSlide.id = id
	if tempCrop:
		iSlide.parse_crop(tempCrop)
	else:
		iSlide.parse_crop(slideshowNode.itemData["crop"])
	iSlide.picTex = slideshowNode.thumbs.get_child(id).texture
	self.add_child(iSlide)
	if !quiet:
		iSlide.fade_in(slideshowNode.itemData["fadeTime"])
	if quiet:
		iSlide.fade_in(0.1)

func start_hold():
	if Global.slideshowRunning:
		holdTimer.wait_time = slideshowNode.itemData["holdTime"]
		holdTimer.start()

func stop_timers():
	holdTimer.stop()
	Global.slideshowRunning = false

func _on_hold_timer_timeout():
	holdTimer.stop()
	for s in self.get_children():
		if s.name != "HoldTimer":
			for c in slideshowNode.thumbs.get_children():
				if s.texture == c.texture:
					current = c.get_index()
			s.fade_out(slideshowNode.itemData["fadeTime"])
	var total = slideshowNode.thumbs.get_child_count()
	if current < total -1:
		load_slide(current+1,false)
	else:
		end_of_slides()


func end_of_slides():
	Global.slideshowRunning = false
	Signals.itemFinished.emit()
