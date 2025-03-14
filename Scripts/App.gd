@tool
extends CanvasLayer

@onready var aspectBox = %AspectPanel
@onready var videoBox = %VideoPlayer
@onready var ExtMonPar = $ExtMon
@onready var loadedVideoTitle = %VideoTitleLabel
@onready var ti = %TimeElapsed
@onready var to = %TimeLeft
@onready var playslider = %PlaySlider
@onready var networkControl: Node = %NetworkControl

@export_tool_button("Options Panel") var optionsPanel = toggle_options
@export_tool_button("Help Panel") var helpPanel = _on_help_button_button_up

func toggle_options():
	if %SettingsPopup.visible:
		%BlurPanel.hide()
		%SettingsPopup.hide()
	else:
		%BlurPanel.show()
		%SettingsPopup.show()


var muted = preload("res://UI/Icons/mute on.png")
var unmuted = preload("res://UI/Icons/mute off.png")

var loopIcon = preload("res://UI/Icons/loop.png")
var autoIcon = preload("res://UI/Icons/Auto.png")

var ider = preload("res://Scenes/identifier.tscn")
var outputWindow = preload("res://Scenes/extended_window.tscn")

var videoPlaylistItem = preload("res://Scenes/playlist_video_item.tscn")
var slideshowPlaylistItem = preload("res://Scenes/playlist_slideshow_item.tscn")
var stillPlaylistItem = preload("res://Scenes/playlist_still_item.tscn")

var extended = false

var playlist = true

var aspect
var full = false
var lastDir
var playing = false

var selectedItem
var mute = false
var elapsed
var left
var seeking = false
var trimmed = false
var server = null

var listening = false

var extMons
var ExtendedMonitor = 1




func go_to_video(rxCommand):
	var totalItems = %VideoList.get_child_count()
	
	if rxCommand == "previous":
		if Global.activeIndex <= 0:
			Global.activeIndex = totalItems - 1
		else: 
			Global.activeIndex -= 1
	if rxCommand == "next":
		if Global.activeIndex < totalItems:
			Global.activeIndex += 1
		if Global.activeIndex == totalItems:
			Global.activeIndex = 0

	print(selectedItem)
	%VideoList.get_child(Global.activeItem)._on_select_video_button_button_up()
	print("next video")

func trim_point(rxCommand):
	var totalItems = %VideoList.get_child_count()
	
	if totalItems and Global.activeIndex:
		if rxCommand == "SetIn":
			print("set in")
			Global.activeItem._on_trim_in_button_up()
			Global.activeItem._on_select_video_button_button_up()
		if rxCommand == "SetOut":
			print("set in")
			Global.activeItem._on_trim_out_button_up()
			Global.activeItem._on_select_video_button_button_up()
	else:
		print("error")

func adj_vol(rxCommand):
	if rxCommand == "VolUp":
		var new = %Volume.value + 2
		_on_volume_drag_ended(new)

	if rxCommand == "VolDown":
		var new = %Volume.value - 2
		_on_volume_drag_ended(new)

# MAIN 
func _ready():
	if !Engine.is_editor_hint():
		%BlurPanel.hide()
		Global.app = self
		$Timer.start()
		Signals.queueItem.connect(queue_item)
		Signals.sort.connect(move_video)
		Signals.videoInfo.connect(check_position)
		#Signals.timeHover.connect(time_hover)
		Signals.itemFinished.connect(_on_video_player_finished)
		Signals.slide.connect(update_tick)
		Signals.errorMsg.connect(error_message)

		check_cmd_args()
		
		
		#Disabled Licensing Check
		#%Trial.start()
		#Auth.check_saved_key()
		Signals.validation.emit(true)
	
	if extMons != DisplayServer.get_screen_count():
		extMons = DisplayServer.get_screen_count()
		for m in extMons:
			%MonitorSelector.add_item(str(m + 1))
	
		Signals.validation.emit(true)


func check_cmd_args():
	var arguments = {}
	var path
	print("arguments: " + str(arguments))
	if arguments != {  }:
		for argument in OS.get_cmdline_args():
			if argument.find("=") > -1:
				var key_value = argument.split("=")
				arguments[key_value[0].lstrip("--")] = key_value[1]
			if argument:
				# Options without an argument will be present in the dictionary,
				# with the value set to an empty string.
				if argument != "res://app.tscn":
					arguments["Playlist File"] = argument.lstrip("--")
					path = str(argument.lstrip("--"))
					%Playlist.load_playlist(path)


func check_position(pos):
	if Global.activeItem:
		if !seeking and Global.activeType == "video":
			playslider.value = pos
			elapsed = playslider.value
			left = Global.activeItem.itemData["length"] - playslider.value
			ti.text = str( "+" + secondsToMMSS(elapsed))
			to.text = str( "-" + secondsToMMSS(left))
			if !videoBox.paused:
				networkControl.update_time(ti.text,to.text)

		if Global.activeType == "video" and playslider.value >= Global.activeItem.itemData["endPoint"]:
			print("video reached end point: " + str(playslider.value) + " - " + str(Global.activeItem.itemData["endPoint"]))
			_on_video_player_finished()

func _process(_delta):
	if not Engine.is_editor_hint():
		
		if extended:
			if Input.is_action_pressed("ExtClose"):
				_on_confirm_yes_button_up()
		
		if !%Trial.is_stopped():
			var trialLeft = secondsToMMSS(%Trial.get_time_left())
			%TrialTimeLabel.text = "Time till Watermark Appears: " + trialLeft + "\nActivate to Remove"
		
		if Input.is_action_just_released("ui_accept"):
			_on_play_pause_button_up()
		if Global.activeType == "video":
			if Input.is_action_pressed("Mod"):
				if Input.is_action_pressed("Ctrl"):
					if Input.is_action_just_pressed("ui_right"):
						var current = playslider.value
						current += 60
						Signals.setPos.emit(current)
					if Input.is_action_just_pressed("ui_left"):
						var current = playslider.value
						current -= 60
						Signals.setPos.emit(current)
				elif Input.is_action_just_pressed("ui_right"):
					var current = playslider.value
					current += 10
					Signals.setPos.emit(current)
				elif Input.is_action_just_pressed("ui_left"):
					var current = playslider.value
					current -= 10
					Signals.setPos.emit(current)
			elif Input.is_action_just_pressed("ui_right"):
				var current = playslider.value
				current += 1
				Signals.setPos.emit(current)
			elif Input.is_action_just_pressed("ui_left"):
				var current = playslider.value
				current -= 1
				Signals.setPos.emit(current)
		
		if Global.activeType == "slideshow":
			if !%HoldTimer.is_paused() and !%HoldTimer.is_stopped():
				%SlideHoldBar.max_value = %HoldTimer.get_wait_time()
				var inverse = %SlideHoldBar.max_value - %HoldTimer.get_time_left()
				%SlideHoldBar.value = inverse
				%SlideHoldBar.visible = true
			elif %HoldTimer.is_paused() or %HoldTimer.is_stopped():
				%SlideHoldBar.value = 0
				%SlideHoldBar.visible = true
		else:
			%SlideHoldBar.visible = false


func update_tick(id):
	%TimeElapsed.text = str(id + 1)
	%PlaySlider.value = id + 1
	

func secondsToMMSS(seconds):
	var minutes = seconds / 60
	var remainingSeconds = int(seconds) % 60
	var outputFormat = "%02d:%02d"
	var output = outputFormat % [floor(minutes) , round(remainingSeconds)]
	return output


func _on_options_button_button_up() -> void:
	%BlurPanel.show()
	%SettingsPopup.show()



#func time_hover(status):
	#%PlayHeadBG.visible = status


func _on_play_pause_button_up():
	set_play_icon()

func reset_play_icon():
	%PlayPause.icon = load("res://UI/Icons/play on.png")
	Global.playIcon = true

func set_play_icon():
	if Global.activeType == "video":
		Signals.pauseToggle.emit()
		if %VideoPlayer.is_playing() and %VideoPlayer.paused:
			%PlayPause.icon = load("res://UI/Icons/play on.png")
			Global.playIcon = true
		if %VideoPlayer.is_playing() and !%VideoPlayer.paused:
			%PlayPause.icon = load("res://UI/Icons/pause on.png")
			Global.playIcon = false
	if Global.activeType == "slideshow":
		Global.slideshowRunning = !Global.slideshowRunning
		if !Global.playIcon:
			Signals.pauseSlides.emit()
			%PlayPause.icon = load("res://UI/Icons/play on.png")
			Global.playIcon = true
		elif Global.playIcon:
			Signals.startSlides.emit(playslider.value)
			%PlayPause.icon = load("res://UI/Icons/pause on.png")
			Global.playIcon = false
		


func _on_stop_button_up():
	videoBox.stop()
	videoBox.stream = null

func _on_volume_edit_focus_exited() -> void:
	_on_volume_edit_text_submitted(%VolumeEdit.text)


func _on_volume_drag_ended(_value_changed):
	if Global.activeType == "video":
		var player
		if extended:
			player = "ExtendedVideoPanel"
		else:
			player = "MainVideoPanel"
		Signals.setVol.emit(player,%Volume.value) # Recieved by Playlist Video Item and Video Panels
		%VolMute.text = "🔊"



func _on_vol_mute_button_up():
	if %Volume.value == -80:
		print("unmute")
		%VolMute.text = "🔊"
		%Volume.value = Global.activeItem.itemData["volume"]
		_on_volume_drag_ended(%Volume.value)
	elif %Volume.value != -80:
		print("mute")
		%VolMute.text = "🔇"
		%Volume.value = -80
		_on_volume_drag_ended(%Volume.value)


func _on_volume_value_changed(value: float) -> void:
	var dB = int(value)
	%VolumeEdit.text = str(dB)


func _on_volume_edit_text_submitted(new_text: String) -> void:
	var dB
	if new_text == "0":
		print("set to 0")
		dB = 0
	elif int(new_text):
		print("new vol: " + str(int(new_text)))
		dB = int(new_text)
	else:
		print("new vol not int: " + str(int(new_text)))
		%VolumeEdit.text = str(%Volume.value)
	
	if dB >= -80 or dB <= 20:
		%Volume.value = float(dB)
		_on_volume_drag_ended(float(dB))
	else:
		%VolumeEdit.text = str(%Volume.value)
		

func _on_add_video_button_button_up():
	%OpenVideoFileDialog.show()

func _on_add_slideshow_button_button_up():
	%OpenSlideshowFileDialog2.show()

func add_to_playlist(type,path):
	lastDir = path.get_base_dir()
	print("lastdir: " + lastDir)
	
	if videoBox.is_playing() and !videoBox.is_paused():
		clear_errors()
		error_message("Can't load while video playback is running. \n Wait for playback to finish or pause playback to load.")
	else:
		if type == "video":
			%OpenVideoFileDialog.root_subfolder = lastDir
			var iVideo = videoPlaylistItem.instantiate()
			iVideo.title = path_cut(path)
			iVideo.itemData["path"] = path
			%VideoList.add_child(iVideo)

		
		if type == "slideshow":
			var iSlideshow = slideshowPlaylistItem.instantiate()
			iSlideshow.title = path_cut(path)
			iSlideshow.itemData["folder"] = path
			%VideoList.add_child(iSlideshow)
		
		if type == "still":
			var iStill = stillPlaylistItem.instantiate()
			iStill.title = path_cut(path)
			iStill.itemData["path"] = path
			%VideoList.add_child(iStill)
		
		var total = %VideoList.get_child_count() - 1
		for v in %VideoList.get_children():
			v.total = total
			v.id = v.get_index() + 1
	#		v.check_index()

func path_cut(path):
	var fileName = path.get_file()
	var ext =  "." + fileName.get_extension()
	var videoName = fileName.get_slice(ext,0)
	return videoName


func queue_item(type,itemData):
	if type == "video":
		playslider.value = 0
		playslider.max_value = itemData["length"] - 1
		playslider.min_value = 0

		if itemData["length"] < 600:
			playslider.tick_count = itemData["length"] / 2
		elif itemData["length"] > 3600:
			playslider.tick_count = itemData["length"] / 120
		else:
			playslider.tick_count = itemData["length"] / 60
		
		ti.text = "00:00"
		to.text = str( "-" + secondsToMMSS(itemData["length"]))
		if itemData["muted"]:
			%Volume.value = -80
		else:
			%Volume.value = itemData["volume"]
		_on_volume_drag_ended(%Volume.value)
		%VideoTitleLabel.text = path_cut(itemData["path"])
		networkControl.update_time(itemData["startPoint"],itemData["endPoint"])
		%VolumeControls.visible = true

		%PlayBar.visible = true
		%VideoControls.visible = true
		if itemData["endPoint"] != itemData["length"] or itemData["startPoint"] != 0:
			print("video trimmed")
			trimmed = true
			%TrimTimes.visible = true
			%TimeTrimIn.text = secondsToMMSS(itemData["startPoint"])
			%TimeTrimOut.text = secondsToMMSS(itemData["endPoint"])
		else:
			print("video not trimmed")
			trimmed = false
			%TrimTimes.visible = false
	
	if type == "slideshow":
		Signals.stopVideo.emit()
		%VideoTitleLabel.text = Global.activeItem.title
		var total = 0
		for e in itemData:
			total += 1
		playslider.min_value = 1
		playslider.value = 1
		playslider.max_value = total
		playslider.tick_count = total
		to.text = str(total)
		ti.text = str(1)
		%VolumeControls.visible = false

		%PlayBar.visible = true
		%VideoControls.visible = true
		trimmed = false
		%TrimTimes.visible = false
		
	if type == "still":
		Signals.stopVideo.emit()
		%VideoTitleLabel.text = Global.activeItem.title
		%VolumeControls.visible = false

		%PlayBar.visible = false
		%VideoControls.visible = false
		trimmed = false
		%TrimTimes.visible = false
	
	reset_play_icon()


func move_video(node,index):
	%VideoList.move_child(node,index)
	node.id = node.get_index()
	var total = %VideoList.get_child_count()
	for v in %VideoList.get_children():
		v.total = total
		v.id = v.get_index() + 1
#		v.check_index()



func probe(path):
	var time = path.get_length()
	print(time)
	return time

func _on_open_slideshow_file_dialog_2_dir_selected(dir):
	var type = "slideshow"
	add_to_playlist(type,dir)

func _on_open_video_file_dialog_file_selected(path):
	var type = "video"
	add_to_playlist(type,path)

func _on_open_still_file_dialog_file_selected(path):
	var type = "still"
	add_to_playlist(type,path)

func _on_play_slider_drag_ended(_value_changed):
	if Global.activeType == "video":
		Signals.setPos.emit(playslider.value)
	#	videoBox.set_stream_position(playslider.value)
		seeking = false
		#Signals.pauseToggle.emit()

		%SliderLabel.hide()
	if Global.activeType == "slideshow":
		if Global.playIcon:
			Signals.setSlide.emit(playslider.value - 1,true)
		else:
			Signals.setSlide.emit(playslider.value - 1,false)

func _on_play_slider_drag_started():
	if Global.activeType == "video":
		%SliderLabel.show()
		#Signals.pauseToggle.emit()

		seeking = true
	if Global.activeType == "slideshow":
		Signals.pauseSlides.emit()

func _on_play_slider_value_changed(value: float) -> void:
	pass

func _on_loop_toggle_button_up():
	Global.loop = !Global.loop
	print("loop: " + str(Global.loop))
	set_loop_icon()

func set_loop_icon():
	if Global.loop:
		%LoopToggle.icon = load("res://UI/Icons/loop on.png")
		Global.auto = false
		set_auto_icon()
	else:
		%LoopToggle.icon = load("res://UI/Icons/loop off.png")

func _on_auto_toggle_button_up():
	Global.auto = !Global.auto
	print("auto: " + str(Global.auto))
	set_auto_icon()

func set_auto_icon():
	if Global.auto:
		%AutoToggle.icon = load("res://UI/Icons/auto on.png")
		Global.loop = false
		set_loop_icon()
	else:
		%AutoToggle.icon = load("res://UI/Icons/auto off.png")

func check_next_video():
	var videosAmount = %VideoList.get_child_count()
	var nextVideoIndex
	var nextVideoNode
	
	for i in %VideoList.get_children():
		if i == Global.activeItem:
			Global.activeIndex = i.get_index()
	
	if Global.activeIndex == videosAmount - 1:
		nextVideoIndex = null
		print("last video in list played")
	else:
		nextVideoIndex = Global.activeIndex + 1
	
	if nextVideoIndex != null:
		nextVideoNode = %VideoList.get_child(nextVideoIndex)
	
	print("next video index: " + str(nextVideoIndex))
	
	return nextVideoNode


func _on_video_player_finished():
	print("finished")
	if Global.loop:
		print("please loop")
		print(Global.activeType)
		if Global.activeType == "video":
			Global.activeItem._on_select_video_button_button_up()
			_on_play_pause_button_up()
			print("looping video")
		if Global.activeType == "slideshow":
			print("looping slideshow")
			Signals.setSlide.emit(0,false)

	elif Global.auto:
		print("please auto advance")
		print("checking for next video in list")
		if check_next_video():
			var nextVideoNode = check_next_video()
			nextVideoNode._on_select_video_button_button_up()
			_on_play_pause_button_up()
			print("playing next item")
		
	else:
		Signals.stopVideo.emit()
		print("not looping")


func _on_timer_timeout():
	if not Engine.is_editor_hint():
		Server.check_connection()


func _on_monitor_selector_button_down():
	print(extended)
	if !extended:
		for c in ExtMonPar.get_children():
			c.queue_free()
		if extMons != DisplayServer.get_screen_count():
			%MonitorSelector.clear()
			extMons = DisplayServer.get_screen_count()
			for m in extMons:
				%MonitorSelector.add_item(str(m + 1))
			
		for m in extMons: # Starts at 0
			var iIder = ider.instantiate()
			
			
			iIder.id = m
			get_viewport().set_embedding_subwindows(false)
			ExtMonPar.add_child(iIder)
			iIder.current_screen = m
			print("setting ider to: " + str(iIder.current_screen))


func _on_monitor_selector_item_selected(index):
	ExtendedMonitor = index + 1


func _on_extend_button_button_up():
	if extended:
		%BlurPanel.show()
		%ExtCloseConfirm.show()
		%ErrorMessage.hide()
		
	else:
		
		if Global.activeType == "video":
			%VideoPlayer.volume_db = -100
			if %VideoPlayer.is_playing():
				var e = outputWindow.instantiate()
				var playPos = %VideoPlayer.get_stream_position()
				var volume = %Volume.value
				var paused
				if %VideoPlayer.paused:
					paused = true
				else:
					paused = false
				spawn_window(e)
				Signals.videoExtended.emit(%VideoPlayer.stream,Global.activeItem.itemData["width"],Global.activeItem.itemData["height"],playPos,volume,paused)
				
		
		elif Global.activeType == "slideshow":
			var e = outputWindow.instantiate()
			if Global.slideshowRunning:
				spawn_window(e)
				Signals.slideshow.emit(Global.activeItem)
				Signals.setSlide.emit(Global.activeSlide,true)
		
		else:
			var e = outputWindow.instantiate()
			spawn_window(e)
		


func spawn_window(instance):
		if ExtendedMonitor != null:
			ProjectSettings.set_setting("display/window/size/always_on_top", true)
			get_viewport().set_embedding_subwindows(false)
			ExtMonPar.add_child(instance)
			instance.visible = true
			instance.mode = 4
			instance.current_screen = int(ExtendedMonitor)-1
			extended = true
			%ExtendButton.icon = load("res://UI/Icons/Output_Enabled.png")
		

func _on_confirm_yes_button_up():
	for c in ExtMonPar.get_children():
		c.queue_free()
	extended = false
	%VideoPlayer.volume_db = %Volume.value
	%BlurPanel.hide()
	%ExtendButton.icon = load("res://UI/Icons/Output.png")
	get_tree().get_root().always_on_top = false


func _on_confirm_no_button_up():
	%BlurPanel.hide()



func _on_help_button_button_up():
	%MainVideoPanel.visible = !%MainVideoPanel.visible
	%HelpPanel.visible = !%HelpPanel.visible




func _on_aspect_option_button_item_selected(index):
	Signals.setCrop.emit(index)


func _on_set_aspect_button_up():
	pass # Replace with function body.
	Signals.setAspect.emit(aspect)


func _on_video_list_sort_children():
	if not Engine.is_editor_hint():
		for i in %VideoList.get_children():
			if i.name != "Deleter":
				i.id = i.get_index()
		if Global.activeItem and %VideoList.get_child_count() > 1:
			check_next_video()

func _on_add_still_button_button_up():
	%OpenStillFileDialog.show()






func _on_test_pattern_button_up():
	Global.testPattern = !Global.testPattern
	if Global.testPattern:
		%TestPattern.text = " ✅"
	else:
		%TestPattern.text = " 🔳"
	if !Engine.is_editor_hint():
		Signals.testPattern.emit(Global.testPattern)


func _on_trial_timeout():
	print("watermark enabled")
	Auth.watermark = true
	Signals.watermarkEnable.emit()
	%Trial.stop()
	%TrialTimeLabel.text = "Watermark Enabled on Output"


func _on_trial_dialog_close_button_up():
	%TrialDialog.visible = false

func clear_errors():
	%ErrorLabel.text = ""

func error_message(message):
	print("errors recieved: " + str(message))
	var currentMsg = %ErrorLabel.text
	var newMsg = currentMsg + "\n⚠️ - " + message
	%ErrorLabel.text = newMsg
	%BlurPanel.show()
	%ExtCloseConfirm.hide()
	%ErrorMessage.show()

func _on_error_close_button_button_up():
	%BlurPanel.hide()


func _on_gui_margin_resized() -> void:
	pass

func _on_ndi_monitor_button_up() -> void:
	find_and_run_exe("C:/Program Files/NDI", "StudioMonitor")
	
func find_and_run_exe(directory: String, search_string: String):
	# Get the File and Directory access API
	var dir := DirAccess.open(directory)
	if dir == null:
		print("Failed to open directory: ", directory)
		return
	
	# Scan directory
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := directory + "/" + file_name # Correct path concatenation
		
		# Check if it's a directory and recursively search inside
		if dir.current_is_dir():
			find_and_run_exe(full_path, search_string)
		else:
			# Check if it's an executable and contains the search string
			if file_name.ends_with(".exe") and search_string in file_name:
				print("Found executable: ", full_path)
				OS.create_process(full_path, [])
				return # Exit after running the first match
		
		file_name = dir.get_next()
