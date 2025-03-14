extends Node

@onready var holdTimer = $HoldTimer

var current = null
var slide = preload("res://Scenes/slideshow_pic.tscn")
var still = preload("res://Scenes/Still_Image.tscn")
var waiting = false

var slideshowOptions = {
	"folder": null,
	"pics": [],
	"holdTime": 4.0,
	"fadeTime": 2.0,
	"fit": true,
	"crop": false,
	"bgColor": Color(0,0,0),
}

var slideshowNode

func _ready():
	Signals.startSlides.connect(start_slides)
	Signals.pauseSlides.connect(stop_timers)
	Signals.setSlide.connect(go_to_slide)
	Signals.updateSlideOptions.connect(update_options)
	Signals.shuffleSlides.connect(shuffle_slides)
	Signals.slideshow.connect(load_node)


func load_node(node):
	slideshowNode = node
	self.visible = true
	print("slideshow node: " + str(node))

func load_still(stillData):
	var iStill = still.instantiate()
	iStill.picPath = stillData["path"]
	self.add_child(iStill)
	iStill.update_options("fit",stillData["fit"])
	iStill.update_options("crop",stillData["crop"])
	

func start_slides(sliderValue):
	if sliderValue == 1:
		go_to_slide(0,false)
	else:
		for s in self.get_children():
			if s.name != "HoldTimer":
				if s.self_modulate != Color.WHITE:
					s.fade_in(slideshowOptions["fadeTime"])
				else:
					s.fade_in_finished()

func shuffle_slides():
	go_to_slide(0,true)

func update_options(option,value):
	slideshowOptions[option] = value
	for s in self.get_children():
		if s.name != "HoldTimer":
			s.update_options(option,value)

func clear_slideshow():
	for p in self.get_children():
		if p.name != "HoldTimer":
			p.queue_free()
	Signals.slideshowRunning = false

func go_to_slide(id,quiet):
	for s in self.get_children():
		if s.name != "HoldTimer":
			s.fade_out(slideshowOptions["fadeTime"])

	load_slide(id,quiet)

func load_slide(id,quiet):
	Signals.slideshowRunning = true
	Signals.slide.emit(id)
	Signals.activeSlide = id
	var iSlide = slide.instantiate()
	iSlide.id = id
	iSlide.update_options("fit",slideshowOptions["fit"])
	iSlide.update_options("crop",slideshowOptions["crop"])
	iSlide.picTex = slideshowNode.thumbs.get_child(id).texture
	self.add_child(iSlide)
	if !quiet:
		iSlide.fade_in(slideshowOptions["fadeTime"])
	if quiet:
		iSlide.fade_in(0.1)

func start_hold():
	if Signals.slideshowRunning:
		holdTimer.wait_time = slideshowOptions["holdTime"]
		holdTimer.start()

func stop_timers():
	holdTimer.stop()
	Signals.slideshowRunning = false

func _on_hold_timer_timeout():
	holdTimer.stop()
	for s in self.get_children():
		if s.name != "HoldTimer":
			for c in slideshowNode.thumbs.get_children():
				if s.texture == c.texture:
					current = c.get_index()
			s.fade_out(slideshowOptions["fadeTime"])
	var total = slideshowNode.thumbs.get_child_count()
	if current < total -1:
		load_slide(current+1,false)
	else:
		end_of_slides()


func end_of_slides():
	Signals.slideshowRunning = false
	Signals.itemFinished.emit()
