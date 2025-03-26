extends Panel

# Aspect Panel can move around and scale inside, TODO: implement optional controls for pan and zoom

@onready var videoBox = %VideoPlayer
@onready var aspectBox = %AspectPanel
@onready var slideshowPanel = %SlideShow
@onready var canvasBG: Panel = %CanvasBG
@onready var audioPlayer: AudioStreamPlayer = %AudioPlayer

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
		
		if audioPlayer.playing:
			var pos = audioPlayer.get_playback_position()
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
		
	if type == "audio": #unused so far
		audioPlayer.stream = Global.activeItem.resource
		audioPlayer.play()
		audioPlayer.seek(itemData["startPoint"])
		await get_tree().process_frame
		audioPlayer.stream_paused = true
		print("audio ready at: " + Utils.Secs_To_MMSS(audioPlayer.get_playback_position()))

		
	if type == "slideshow": # [pics,holdTime,fadeTime,crop,bgColor]
		videoBox.visible = false
		slideshowPanel.visible = true
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
	if type == "audio":
		print("unloading audio")
		audioPlayer.stop()
		audioPlayer.stream = null
	if type == "slideshow":
		print("unloading slideshow")
		slideshowPanel.stop_timers()
		for p in slideshowPanel.get_children():
			if p.name != "HoldTimer":
				p.queue_free()
		Global.slideshowRunning = false
	Global.app.reset_play_icon()


func update_canvas():
	%VideoSubViewport.set_deferred("size",Vector2(Global.outputResolution.x,Global.outputResolution.y))
	slideshowPanel.set_deferred("size",Vector2(Global.outputResolution.x,Global.outputResolution.y))
	%CanvasBG.set_deferred("size",Vector2(Global.outputResolution.x,Global.outputResolution.y))


func set_aspect(aspect):
	aspectBox.ratio = aspect

func set_crop(cropMode):
	if Global.activeType == "video":
		aspectBox.stretch_mode = cropMode
	elif Global.activeType == "still" or Global.activeType == "slideshow":
		Signals.updateSlideCrop.emit(cropMode)


func pause_toggle():
	if Global.activeType == "video":
		if videoBox.paused:
			videoBox.paused = false
		else:
			videoBox.paused = true
		
		if !videoBox.is_playing():
			videoBox.play()
			videoBox.paused = false
			print("video started")
	
	if Global.activeType == "audio":
		if !audioPlayer.playing:
			audioPlayer.stream_paused = false
			print("audio resumed")
		else:
			audioPlayer.stream_paused = true
			print("audio paused")
			
		
	


func set_pos(pos):
	if Global.activeType == "video":
		videoBox.set_stream_position(pos)
	if Global.activeType == "audio":
		audioPlayer.seek(pos)

func set_volume(player,value):
	Global.lastVolume = value
	if player == self.name:
		if Global.activeType == "video":
			videoBox.volume_db = value
		if Global.activeType == "audio":
			audioPlayer.volume_db = value
		print("adjusting volume on: " + player)

func mute(status):
	if status == true:
		if Global.activeType == "video":
			Global.lastVolume = videoBox.volume_db
			videoBox.volume_db = -80
		if Global.activeType == "audio":
			Global.lastVolume = audioPlayer.volume_db
			audioPlayer.volume_db = -80
	else:
		if Global.activeType == "video":
			videoBox.volume_db = Global.lastVolume
			Global.lastVolume = videoBox.volume_db
		if Global.activeType == "audio":
			audioPlayer.volume_db = Global.lastVolume
			Global.lastVolume = audioPlayer.volume_db

func play_current(extendedData):
	if self.name == "ExtendedVideoPanel":
		
		if Global.activeType == "video":
			videoBox.stream = extendedData["stream"]
			var aspect = float(extendedData["width"])/float(extendedData["height"])
			aspectBox.ratio = aspect
			videoBox.volume_db = extendedData["volume"]
			videoBox.play()
			videoBox.set_stream_position(extendedData["pos"])
			videoBox.paused = extendedData["paused"]
		
		if Global.activeType == "audio":
			audioPlayer.stream = extendedData["stream"]
			audioPlayer.volume_db = extendedData["volume"]
			audioPlayer.play()
			audioPlayer.seek(extendedData["pos"])
			audioPlayer.stream_paused = extendedData["paused"]


func _on_video_player_finished():
	Signals.itemFinished.emit()

func _on_audio_player_finished() -> void:
	Signals.itemFinished.emit()

func _on_tips_gui_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click") and %Tips.visible:
		%Tips.visible = false


func _on_tips_never_button_up() -> void:
	Global.showTips = !Global.showTips
	if Global.showTips:
		%TipsNever.text = "🔳"
	else:
		%TipsNever.text = "✅"
