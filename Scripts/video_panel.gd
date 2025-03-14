extends Panel

# Aspect Panel can move around and scale inside, TODO: implement optional controls for pan and zoom

@onready var videoBox = %VideoPlayer
@onready var aspectBox = %AspectPanel
@onready var slideshowPanel = %SlideShow

var slideshowPic = preload("res://Scenes/slideshow_pic.tscn")

var main

func _ready():
	update_canvas()
	aspectBox.stretch_mode = 2
	Signals.queueItem.connect(queue_item)
	Signals.stopVideo.connect(stop_video)
	Signals.startVideo.connect(start_video)
	Signals.setAspect.connect(set_aspect)
	Signals.setCrop.connect(set_crop)
	Signals.pauseToggle.connect(pause_toggle)
	Signals.setPos.connect(set_pos)
	Signals.setVol.connect(set_volume)
	Signals.removeItem.connect(remove_item)
	Signals.videoExtended.connect(play_current)
	Signals.changedResolution.connect(update_canvas)
	if self.name == "MainVideoPanel":
		main = true
	else: main = false
	
	if !Global.showTips:
		%Tips.hide()
	



func _process(_delta):
	if is_instance_valid(Signals):


		if videoBox.is_playing():
			var pos = videoBox.stream_position
			Signals.videoInfo.emit(pos)


func stop_video():
	videoBox.stop()

func start_video():
	videoBox.paused = false
	videoBox.play()

func queue_item(type,itemData): # [path,startPoint,endPoint,length,width,height,volume]
	if type == "video":
		videoBox.visible = true
		slideshowPanel.visible = false
		var resource := Global.playbackEngine.new()
		resource.file = itemData["path"]
		print("resource: ", resource.file)
		videoBox.stream = resource
		var aspect = float(itemData["width"])/float(itemData["height"])
		aspectBox.ratio = aspect
		aspectBox.stretch_mode = itemData["crop"]
		videoBox.play()
		videoBox.paused = true
		videoBox.set_stream_position(itemData["startPoint"])
		slideshowPanel.stop_timers()
		slideshowPanel.clear_slideshow()
	
	if type == "slideshow": # [pics,holdTime,fadeTime,crop,bgColor]
		videoBox.visible = false
		slideshowPanel.visible = true
		slideshowPanel.slideshowOptions = Global.activeItem.itemData
		slideshowPanel.stop_timers()
		slideshowPanel.clear_slideshow()
		
	if type == "still":
		videoBox.visible = false
		slideshowPanel.visible = true
		slideshowPanel.stop_timers()
		slideshowPanel.clear_slideshow()
		slideshowPanel.load_still(itemData)
		



func remove_item(type):
	if type == "video":
		print("unloading video")
		videoBox.stop()
		videoBox.stream = null
	if type == "slideshow":
		print("unloading slideshow")
		slideshowPanel.stop_timers()
		for p in slideshowPanel.get_children():
			if p.name != "HoldTimer":
				p.queue_free()
		Global.slideshowRunning = false
	Global.app.reset_play_icon()


func update_canvas():
	%VideoSubViewport.size.x = Global.outputResolution.x
	%VideoSubViewport.size.y = Global.outputResolution.y
	slideshowPanel.size.x = Global.outputResolution.x
	slideshowPanel.size.y = Global.outputResolution.y
	%CanvasBG.size.x = Global.outputResolution.x
	%CanvasBG.size.y = Global.outputResolution.y


func set_aspect(aspect):
	aspectBox.ratio = aspect

func set_crop(cropMode):
	aspectBox.stretch_mode = cropMode

func pause_toggle():
	if videoBox.paused == false:
		videoBox.paused = true
	else:
		videoBox.paused = false
	if !videoBox.is_playing():
		videoBox.play()
		videoBox.paused = false
		print("video started")

func set_pos(pos):
	videoBox.set_stream_position(pos)

func set_volume(player,value):
	if player == self.name:
		videoBox.volume_db = value
		print("adjusting volume on: " + player)

func mute(status):
	if status == true:
		videoBox.volume_db = -80
	else:
		videoBox.volume_db = 0

func play_current(currentStream,currentWidth,currentHeight,playPos,volume,paused):
	videoBox.stream = currentStream
	var aspect = float(currentWidth)/float(currentHeight)
	aspectBox.ratio = aspect
	if self.name == "ExtendedVideoPanel":
		videoBox.volume_db = volume
	if paused:
		videoBox.play()
		videoBox.set_stream_position(playPos)
		videoBox.paused = true
	else:
		videoBox.play()
		videoBox.set_stream_position(playPos)
		videoBox.paused = false


func _on_video_player_finished():
	Signals.itemFinished.emit()



func _on_tips_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click") and %Tips.visible:
		%Tips.visible = false


func _on_tips_never_button_up() -> void:
	Global.showTips = !Global.showTips
	if Global.showTips:
		%TipsNever.text = "🔳"
	else:
		%TipsNever.text = "✅"
