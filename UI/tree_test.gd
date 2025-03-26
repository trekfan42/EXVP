@tool
extends Tree

func _ready():
	populate_dummy_playlist_tree()



func populate_dummy_playlist_tree():
	self.clear()  # Clear previous tree data
	var root = self.create_item()  # Root node

	# 🟢 Root Folder (Main Playlist Folder)
	root.set_text(0, "📂 Playlist Folder")

	# Create subfolders
	var images_folder = self.create_item(root)
	images_folder.set_text(0, "📂 Images")

	var slideshows_folder = self.create_item(root)
	slideshows_folder.set_text(0, "📂 Slideshows")

	var videos_folder = self.create_item(root)
	videos_folder.set_text(0, "📂 Videos")
	
	var audio_folder = self.create_item(root)
	audio_folder.set_text(0, "📂 Audio")

	# 🟢 Add Dummy Images
	for i in range(1, 4):
		var image_item = self.create_item(images_folder)
		image_item.set_text(0, "🖼 Image " + str(i))

	# 🟢 Add Dummy Slideshows
	for i in range(1, 3):
		var slideshow_folder = self.create_item(slideshows_folder)
		slideshow_folder.set_text(0, "📂 Slideshow Folder " + str(i))

		# Add dummy images inside the slideshow
		for j in range(1, 3):
			var slideshow_image = self.create_item(slideshow_folder)
			slideshow_image.set_text(0, "🖼 Image " + str(j))

	# 🟢 Add Dummy Videos
	for i in range(1, 3):
		var video_item = self.create_item(videos_folder)
		video_item.set_text(0, "🎥 Video " + str(i))
	
	# 🟢 Add Dummy Audio
	for i in range(1, 3):
		var audio_item = self.create_item(audio_folder)
		audio_item.set_text(0, "🔉 Audio " + str(i))

	# 🟢 Add Playlist File
	var playlist_item = self.create_item(root)
	playlist_item.set_text(0, "📄 Playlist.exvp")
