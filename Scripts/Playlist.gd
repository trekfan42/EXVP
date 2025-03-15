extends VBoxContainer

var videoItem = preload("res://Scenes/playlist_video_item.tscn")
var slideshowItem = preload("res://Scenes/playlist_slideshow_item.tscn")
var stillItem = preload("res://Scenes/playlist_still_item.tscn")

var filePath:String
var loadedFile = FileAccess.open(filePath,FileAccess.READ)

func _ready():
	get_tree().get_root().files_dropped.connect(_getDroppedFilesPath)

func _getDroppedFilesPath(files):
	print(files)
	for p in files:
		check_file_ext(p)

func check_empty():
	if %VideoList.get_child_count() != 0:
		%PlaylistEmptyHint.visible = false
	else:
		%PlaylistEmptyHint.visible = true

func check_file_ext(path):
	var listExts = ["exvp"]
	var ext = path.get_extension()
	print(ext)
	if ext in Global.videoExts:
		print("video loaded")
		load_video(path)
	if ext in Global.picExts:
		print("image loaded")
		load_image(path)
	if ext in listExts:
		print("loading Playlist")
		load_playlist(path)
	if ext == "":
		print("folder")
		load_folder(path)

func load_video(path):
	Global.app.add_to_playlist("video",path)


func load_folder(path):
	Global.app.add_to_playlist("slideshow",path)


func load_image(path):
	Global.app.add_to_playlist("still",path)



func save(savePath):
	var addExt 
	if !savePath.contains(".exvp"):
		addExt = savePath + ".exvp"
	else:
		addExt = savePath
	var file = FileAccess.open(addExt, FileAccess.WRITE)

	var playlistData = {
		"items": [],
	}
	var iter = 1
	for i in %VideoList.get_children():
		var itemKey = str("item " + str(iter))
		playlistData["items"].append(itemKey)
		if i.type == "video":
			playlistData[itemKey] = [i.type,i.title,i.itemData]
		if i.type == "slideshow":
			playlistData[itemKey] = [i.type,i.title,i.itemData]
		if i.type == "still":
			playlistData[itemKey] = [i.type,i.title,i.itemData]
		
		iter += 1
		

	print(playlistData)
	file.store_line(JSON.stringify(playlistData))
	file.close()


func load_playlist(path):
	print("playlist path: " + path)
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_temp = file.get_as_text()
	file.close()
	
	var loadData = {}
	loadData = JSON.parse_string(load_temp)
	
	var items = loadData["items"]
	
	print(loadData)
	
	for v in %VideoList.get_children():
		v.queue_free()
	
	
	
	for i in items:
		
		if loadData[i][0] == "video" and file_check(loadData[i][2]["path"],"Video"): # [path,startPoint,endPoint,length,width,height,volume] 
			var iVideo = videoItem.instantiate()
			iVideo.title = loadData[i][1]
			iVideo.itemData["path"] = loadData[i][2]["path"]
			print("loading video item")
			%VideoList.add_child(iVideo)
			iVideo.itemData["startPoint"] = int(loadData[i][2]["startPoint"])
			iVideo.itemData["endPoint"] = int(loadData[i][2]["endPoint"])
			iVideo.itemData["volume"] = int(loadData[i][2]["volume"])
			iVideo.itemData["muted"] = loadData[i][2]["muted"]
			iVideo.itemData["crop"] = int(loadData[i][2]["crop"])
			iVideo.update_settings_controls()
		
		if loadData[i][0] == "slideshow" and file_check(loadData[i][2]["folder"],"Folder"): # [pics,holdTime,fadeTime,crop,bgColor]
			var iSlideshow = slideshowItem.instantiate()
			iSlideshow.title = loadData[i][1]
			iSlideshow.itemData["folder"] = loadData[i][2]["folder"]
			print("loading slideshow item")
			%VideoList.add_child(iSlideshow)
			iSlideshow.itemData["holdTime"] = loadData[i][2]["holdTime"]
			iSlideshow.itemData["fadeTime"] = loadData[i][2]["fadeTime"]
			iSlideshow.itemData["bgColor"] = loadData[i][2]["bgColor"]
			iSlideshow.itemData["fit"] = loadData[i][2]["fit"]
			iSlideshow.itemData["crop"] = loadData[i][2]["crop"]
		
		if loadData[i][0] == "still" and file_check(loadData[i][2]["path"],"Still"):
			var iStill = stillItem.instantiate()
			iStill.title = loadData[i][1]
			iStill.itemData["path"] = loadData[i][2]["path"]
			print("loading still image")
			%VideoList.add_child(iStill)
			iStill.itemData["bgColor"] = loadData[i][2]["bgColor"]
			iStill.itemData["fit"] = loadData[i][2]["fit"]
			iStill.itemData["crop"] = loadData[i][2]["crop"]
		
		
		
		Global.app._on_stop_button_up()
		Global.app.selectedItem = 0
	


func _on_save_playlist_button_button_up():
	%SavePlaylistDialog.show()


func _on_save_playlist_dialog_file_selected(path):
	save(path)
	print(path)


func _on_load_playlist_button_button_up():
	%LoadPlaylistDialog.show()


func _on_load_playlist_dialog_file_selected(path):
	load_playlist(path)

func file_check(path,type):
	var dir = path.get_slice(path_cut(path),0)
	print("dir: " + dir)
	if type == "Video" or type == "Still":
		var files = DirAccess.get_files_at(dir)
		if files.has(path_cut(path)):
			return true
		else:
			var error = type + " file missing at:   " + path
			Signals.errorMsg.emit(error)
			return false
	if type == "Folder":
		if DirAccess.open(dir).dir_exists(path):
			return true
		else:
			var error = type + " missing at:   " + path
			Signals.errorMsg.emit(error)
			return false

func path_cut(path):
	var fileName = path.get_file()
	return fileName


func _on_video_list_child_entered_tree(node: Node) -> void:
	check_empty()


func _on_video_list_child_exiting_tree(node: Node) -> void:
	check_empty()
