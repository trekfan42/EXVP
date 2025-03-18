extends VBoxContainer

var videoItem = preload("res://Scenes/playlist_video_item.tscn")
var slideshowItem = preload("res://Scenes/playlist_slideshow_item.tscn")
var stillItem = preload("res://Scenes/playlist_still_item.tscn")

@onready var save_popup: HBoxContainer = %SavingProgressPopup
@onready var save_progress: ProgressBar = %SavingProgressBar
@onready var save_status: Label = %SaveText


var filePath:String
var loadedFile = FileAccess.open(filePath,FileAccess.READ)

func _ready():
	save_popup.hide()
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
	var ext = path.get_extension()
	print(ext)
	if ext in Global.videoExts:
		print("video loaded")
		load_video(path)
	if ext in Global.picExts:
		print("image loaded")
		load_image(path)
	if ext == "exvp":
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


# Add these properties at the top of your class
var save_thread: Thread
var thread_result = {
	"progress": 0,
	"status": "Idle",
	"finished": false,
	"vids_keep": {},
	"stills_keep": {},
	"slideshows_keep": {},
	"playlist_data": {"items": []}
}

func bundle_save(bundle_path):
	# Create a new thread for the save operation
	save_thread = Thread.new()
	
	# Ensure the main bundle folder exists
	if !DirAccess.dir_exists_absolute(bundle_path):
		DirAccess.make_dir_absolute(bundle_path)

	# Define subdirectories
	var video_dir = bundle_path + "/Videos/"
	var image_dir = bundle_path + "/Images/"
	var slideshow_dir = bundle_path + "/Slideshows/"

	DirAccess.make_dir_absolute(video_dir)
	DirAccess.make_dir_absolute(image_dir)
	DirAccess.make_dir_absolute(slideshow_dir)

	# Reset thread result
	thread_result = {
		"progress": 0,
		"status": "Starting save operation...",
		"finished": false,
		"vids_keep": {},
		"stills_keep": {},
		"slideshows_keep": {},
		"playlist_data": {"items": []}
	}

	# 🔹 **UI Update: Show Progress Bar Immediately**
	save_popup.visible = true
	save_progress.visible = true
	save_progress.value = 0
	save_status.visible = true
	save_status.text = "Initializing save..."
	%SaveSpinner.status = 1
	await get_tree().process_frame  # Force UI update
	
	# Prepare the data for the thread
	var thread_data = {
		"bundle_path": bundle_path,
		"video_dir": video_dir,
		"image_dir": image_dir,
		"slideshow_dir": slideshow_dir,
		"items": %VideoList.get_children(),
		"total_items": %VideoList.get_child_count()
	}
	
	# Start the thread with the save_thread_function
	save_thread.start(Callable(self, "_save_thread_function").bind(thread_data))
	
	# Create a timer to regularly update the UI
	var update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = 0.1
	update_timer.one_shot = false
	update_timer.timeout.connect(_update_save_progress)
	update_timer.start()


func _save_thread_function(thread_data):
	# Load existing playlist data
	var bundle_path = thread_data["bundle_path"]
	var video_dir = thread_data["video_dir"]
	var image_dir = thread_data["image_dir"]
	var slideshow_dir = thread_data["slideshow_dir"]
	var items = thread_data["items"]
	var total_items = thread_data["total_items"]
	
	var existing_files = {}
	var existing_playlists = []
	var bundle_playlist_path = bundle_path + "/" + bundle_path.get_file() + ".exvp"
	
	var preexisting_playlist_data = false
	
	if FileAccess.file_exists(bundle_playlist_path):
		print("\nOVERWRITING EXISTING SAVE...\n")
		preexisting_playlist_data = true
	else:
		print("\nCREATING NEW SAVE...\n")
	
	# Process new playlist
	var playlist_data = {
		"items": {},
		"canvas": {}
	}
	var iter = 1
	var vids_keep = []
	var stills_keep = []
	var slideshows_keep = {}
	
	for i in items:
		var item_key = "item " + str(iter)
		var original_path = null
		var new_relative_path = null

		# Store files in the correct subdirectory
		if i.type == "video":
			if preexisting_playlist_data:
				original_path = bundle_path + "/" + i.itemData["path"]
				if !FileAccess.file_exists(original_path):
					original_path = i.itemData["path"]
			else:
				original_path = i.itemData["path"]
			new_relative_path = copy_to_bundle_if_needed(bundle_path, original_path, video_dir)
		elif i.type == "still":
			if preexisting_playlist_data:
				original_path = bundle_path + "/" + i.itemData["path"]
				if !FileAccess.file_exists(original_path):
					original_path = i.itemData["path"]
			else:
				original_path = i.itemData["path"]
			new_relative_path = copy_to_bundle_if_needed(bundle_path, original_path, image_dir)
		elif i.type == "slideshow":
			if preexisting_playlist_data:
				original_path = bundle_path + "/" + i.itemData["folder"]
				if !DirAccess.dir_exists_absolute(original_path):
					original_path = i.itemData["folder"]
			else:
				original_path = i.itemData["folder"]
			new_relative_path = copy_slideshow_to_bundle_if_needed(bundle_path, original_path, slideshow_dir)
			
		print("ITEM ORIGINAL PATH: " + original_path)

		if new_relative_path:
			if i.type == "video":
				new_relative_path = "Videos/" + new_relative_path.get_file()
				i.itemData["path"] = new_relative_path
				vids_keep.append(i.title) # Track new files
			elif i.type == "still":
				new_relative_path = "Images/" + new_relative_path.get_file()
				i.itemData["path"] = new_relative_path
				i.itemData["bgColor"] = Color(i.itemData["bgColor"]).to_html(false)
				stills_keep.append(i.title)  # Track new files
			elif i.type == "slideshow":
				new_relative_path = "Slideshows/" + new_relative_path.get_file()
				i.itemData["folder"] = new_relative_path
				i.itemData["bgColor"] = Color(i.itemData["bgColor"]).to_html(false)
				slideshows_keep[new_relative_path] = true  # Track new files


			playlist_data["items"][item_key] = [i.type, i.title, i.itemData]
			

		# Update progress (for the main thread to use)
		thread_result["progress"] = (iter * 50) / total_items  # First half of progress (50%)
		thread_result["status"] = "Saving item " + str(iter) + "/" + str(total_items)
		
		iter += 1
	
	# Cleanup old files
	thread_result["status"] = "Cleaning up old files..."
	thread_result["progress"] = 60
	
	delete_removed_videos(bundle_path, vids_keep)
	delete_removed_stills(bundle_path, stills_keep)
	delete_removed_folders(bundle_path, slideshows_keep)
	
	# Writing Playlist File
	thread_result["status"] = "Finalizing playlist..."
	thread_result["progress"] = 80
	
	playlist_data["canvas"] = {
			"resolution": [Global.outputResolution.x, Global.outputResolution.y],
			"fps": Global.outputFPS
		}
	
	# Save the new playlist
	var file = FileAccess.open(bundle_playlist_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(playlist_data))
	file.close()
	
	# Save final results to be picked up by main thread
	thread_result["progress"] = 100
	thread_result["status"] = "Save Complete!"
	thread_result["finished"] = true
	thread_result["vids_keep"] = vids_keep
	thread_result["stills_keep"] = stills_keep
	thread_result["slideshows_keep"] = slideshows_keep
	
	# Thread automatically exits when function completes
	return thread_result


func _update_save_progress():
	if thread_result == null:
		return

	# Update UI
	save_progress.value = thread_result["progress"]
	save_status.text = thread_result["status"]

	# If the save is finished
	if thread_result["finished"]:
		save_progress.value = 100
		save_status.text = "Save Complete!"
		%SaveSpinner.status = 3

		# Delay UI hiding
		await get_tree().create_timer(1.5).timeout
		save_popup.visible = false
		%SaveSpinner.status = 0

		# Ensure the thread is properly cleaned up
		if save_thread and save_thread.is_alive():
			save_thread.wait_to_finish()

		# 🛑 **Properly remove and clean up the timer**
		for child in get_children():
			if child is Timer and child.timeout.is_connected(_update_save_progress):
				child.stop()
				child.queue_free()  # ✅ Ensures the Timer is removed

		# ✅ **Prevent multiple print statements**
		if thread_result.get("printed", false) == false:
			print("Playlist successfully saved!")
			thread_result["printed"] = true  # Prevents repeated messages




func copy_to_bundle_if_needed(bundle_path, original_path, target_folder):
	print("checking target: " + target_folder)
	if not FileAccess.file_exists(original_path):
		print("⚠ Missing file, skipping:", original_path)
		return null  # Skip missing files

	var filename = original_path.get_file()
	var new_path = target_folder + filename

	# Check if file exists and is unchanged
	if FileAccess.file_exists(new_path):
		var existing_size = FileAccess.open(new_path, FileAccess.READ).get_length()
		var new_size = FileAccess.open(original_path, FileAccess.READ).get_length()

		if existing_size == new_size:
			print("✅ File is unchanged, skipping copy:", new_path)
			return new_path.replace(target_folder.get_base_dir() + "/", "")

		print("🔄 File changed, overwriting:", new_path)

	# Copy the file only if needed
	var file = FileAccess.open(original_path, FileAccess.READ)
	var new_file = FileAccess.open(new_path, FileAccess.WRITE)
	new_file.store_buffer(file.get_buffer(file.get_length()))
	file.close()
	new_file.close()

	print("📂 Copied file:", new_path)
	return new_path.replace(target_folder.get_base_dir() + "/", "")



func copy_slideshow_to_bundle_if_needed(bundle_path, original_folder, slideshow_dir):
	if not DirAccess.dir_exists_absolute(original_folder):
		print("Missing slideshow folder, skipping:", original_folder)
		return null

	var folder_name = original_folder.get_file()
	var new_folder_path = slideshow_dir + folder_name

	# If the folder exists, check if it needs updating
	if new_folder_path in slideshow_dir:
		var existing_files = DirAccess.get_files_at(new_folder_path)
		var new_files = DirAccess.get_files_at(original_folder)

		if existing_files.size() == new_files.size():  # Check if folder contents match
			print("Slideshow folder unchanged, skipping copy:", new_folder_path)
			return new_folder_path.replace(slideshow_dir.get_base_dir() + "/", "")

		print("Slideshow folder changed, overwriting:", new_folder_path)

	# Delete the old folder before copying (if needed)
	if DirAccess.dir_exists_absolute(new_folder_path):
		DirAccess.remove_absolute(new_folder_path)

	# Copy new slideshow folder
	DirAccess.make_dir_absolute(new_folder_path)
	var dir = DirAccess.open(original_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var original_path = original_folder + "/" + file_name
			if FileAccess.file_exists(original_path):
				copy_to_bundle_if_needed(bundle_path, original_path, new_folder_path + "/")
			file_name = dir.get_next()
		dir.list_dir_end()

	print("Copied new slideshow:", new_folder_path)
	return new_folder_path.replace(slideshow_dir.get_base_dir() + "/", "")




func delete_removed_videos(bundle_path, videos_keep):
	print("🔍 Checking for unnecessary videos to delete...")  # DEBUG
	print(videos_keep)
	
	var folder_path = bundle_path + "/Videos"
	if DirAccess.dir_exists_absolute(folder_path):
		var dir_access = DirAccess.open(folder_path)
		if dir_access:
			dir_access.list_dir_begin()
			var file_name = dir_access.get_next()
			while file_name != "":
				var file_path = file_name.get_basename()  # Relative path
				var absolute_path = folder_path + "/" + file_name  # Absolute path
				if path_cut(file_path) not in videos_keep:
					print("🗑 Removing unused file:", absolute_path)  # DEBUG
					DirAccess.remove_absolute(absolute_path)

				file_name = dir_access.get_next()
			dir_access.list_dir_end()


func delete_removed_stills(bundle_path, stills_keep):
	print("🔍 Checking for unnecessary stills to delete...")  # DEBUG
	print(stills_keep)

	var folder_path = bundle_path + "/Images"
	if DirAccess.dir_exists_absolute(folder_path):
		var dir_access = DirAccess.open(folder_path)
		if dir_access:
			dir_access.list_dir_begin()
			var file_name = dir_access.get_next()
			while file_name != "":
				var file_path = file_name.get_basename()  # Relative path
				var absolute_path = folder_path + "/" + file_name  # Absolute path
				if path_cut(file_path) not in stills_keep:
					print("🗑 Removing unused file:", absolute_path)  # DEBUG
					DirAccess.remove_absolute(absolute_path)

				file_name = dir_access.get_next()
			dir_access.list_dir_end()





func delete_removed_folders(bundle_path, new_folders):
	print("🔍 Checking for unnecessary slideshow folders to delete...")  # DEBUG
	print(new_folders)
	var slideshow_path = bundle_path + "/Slideshows"
	
	var new_slideshow_folder_rel_paths = new_folders.keys()
	
	if DirAccess.dir_exists_absolute(slideshow_path):
		var dir_access = DirAccess.open(slideshow_path)
		if dir_access:
			dir_access.list_dir_begin()
			var folder_name = dir_access.get_next()

			while folder_name != "":
				var folder_path = "Slideshows/" + folder_name  # Relative path
				var absolute_path = slideshow_path + "/" + folder_name  # Absolute path

				# 🔹 Check if this folder is still in the playlist
				var folder_is_used = false
				for new_folder in new_slideshow_folder_rel_paths:
					if folder_path == new_folder:
						folder_is_used = true
						print("keeping slideshow: " + folder_path)
						break  # Stop checking once we find a match

				# 🔹 If the folder is NOT in the new playlist, delete it
				if not folder_is_used:
					print("🗑 Removing unused slideshow folder and contents:", absolute_path)  # DEBUG

					# First, delete all files inside the folder
					var sub_dir = DirAccess.open(absolute_path)
					if sub_dir:
						sub_dir.list_dir_begin()
						var file_name = sub_dir.get_next()
						while file_name != "":
							var file_path = absolute_path + "/" + file_name
							if FileAccess.file_exists(file_path):
								print("🗑 Deleting file in slideshow:", file_path)  # DEBUG
								DirAccess.remove_absolute(file_path)
							file_name = sub_dir.get_next()
						sub_dir.list_dir_end()

					# Now delete the folder itself
					if DirAccess.dir_exists_absolute(absolute_path):
						print("🗑 Deleting empty slideshow folder:", absolute_path)  # DEBUG
						DirAccess.remove_absolute(absolute_path)

				folder_name = dir_access.get_next()
			dir_access.list_dir_end()




func load_playlist(path):
	print("Loading playlist:", path)

	# Extract bundle_path from the playlist file location
	var bundle_path = path.get_base_dir()
	print("Inferred bundle path:", bundle_path)

	var file = FileAccess.open(path, FileAccess.READ)
	var load_temp = file.get_as_text()
	file.close()

	var loadData = JSON.parse_string(load_temp)

	print("Loaded data:", loadData)

	# Clear existing playlist items
	for v in %VideoList.get_children():
		v.queue_free()
	
	# Load items from the saved playlist
	for i in loadData["items"].keys():

		if i in loadData["items"] and loadData["items"][i] is Array and loadData["items"][i].size() > 2:
			var item_type = loadData["items"][i][0]  # ✅ Type at index [0]
			var item_title = loadData["items"][i][1]  # ✅ Title at index [1]
			var item_data = loadData["items"][i][2] # ✅ itemData at index [2]

			var new_item = null
			var rel_path = ""
			var absolute_path = ""

			# Determine absolute path correctly
			if "path" in item_data:
				rel_path = item_data["path"]
				if not rel_path.is_absolute_path():
					absolute_path = bundle_path + "/" + rel_path  # ✅ Fix incorrect joining
					item_data["path"] = absolute_path

			elif "folder" in item_data:
				rel_path = item_data["folder"]
				if not rel_path.is_absolute_path():
					absolute_path = bundle_path + "/" + rel_path  # ✅ Fix incorrect joining
					item_data["folder"] = absolute_path
			
			
			
			else:
				print("error")
			# Debugging: Print absolute paths to verify correctness
			print("Final absolute path:", absolute_path)

			# Instantiate the correct item
			if item_type == "video" and file_check(absolute_path, "Video"):
				new_item = videoItem.instantiate()
				item_data["crop"] = int(item_data["crop"])
				item_data["width"] = int(item_data["width"])
				item_data["height"] = int(item_data["height"])
				item_data["startPoint"] = int(item_data["startPoint"])
				item_data["endPoint"] = int(item_data["endPoint"])
			elif item_type == "still" and file_check(absolute_path, "Still"):
				new_item = stillItem.instantiate()
				item_data["crop"] = int(item_data["crop"])
				item_data["bgColor"] = Color(item_data["bgColor"])
			elif item_type == "slideshow" and file_check(absolute_path, "Folder"):
				new_item = slideshowItem.instantiate()
				item_data["crop"] = int(item_data["crop"])
				item_data["bgColor"] = Color(item_data["bgColor"])


			# Assign item properties
			if new_item:
				new_item.title = item_title
				new_item.loaded = true
				# ✅ Restore itemData safely
				new_item.itemData = item_data

				%VideoList.add_child(new_item)
		
		else:
			print("error, string index: " , i)
			
	# Reset the UI state
	print("loading canvas settings")
	Global.outputFPS = loadData["canvas"]["fps"]
	Global.outputResolution = Vector2i(int(loadData["canvas"]["resolution"][0]) , int(loadData["canvas"]["resolution"][1]) )
	
	Global.app._on_stop_button_up()
	Global.app.selectedItem = 0




func _on_bundle_save_playlist_button_button_up() -> void:
	%BundleSavePlaylistDialog.show()


func _on_bundle_save_playlist_dialog_dir_selected(dir: String) -> void:
	bundle_save(dir)



func _on_load_playlist_button_button_up():
	%LoadPlaylistDialog.show()


func _on_load_playlist_dialog_file_selected(path):
	load_playlist(path)

func file_check(path, type):
	var dir = path.get_base_dir()  # Use get_base_dir() to ensure a valid directory
	print("Checking path:", path, "Type:", type)

	if type == "Video" or type == "Still":
		var files = DirAccess.get_files_at(dir)
		if files.has(path.get_file()):
			return true
		else:
			var error = type + " file missing at: " + path
			Signals.errorMsg.emit(error)
			return false

	if type == "Folder":
		var dir_access = DirAccess.open(dir)
		if dir_access and dir_access.dir_exists(path):
			return true
		else:
			var error = type + " folder missing at: " + path
			Signals.errorMsg.emit(error)
			return false


func path_cut(path):
	var fileName = path.get_file()
	return fileName


func _on_video_list_child_entered_tree(node: Node) -> void:
	check_empty()


func _on_video_list_child_exiting_tree(node: Node) -> void:
	check_empty()
