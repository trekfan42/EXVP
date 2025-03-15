extends TextureRect

var picPath


func _ready():
	var pic = Image.load_from_file(picPath)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	self.texture = imageTexture



func parse_crop(index):
	if index == 1:
		update_options("fit",true)
		update_options("crop",false)
	if index == 2:
		update_options("fit",false)
		update_options("crop",false)
	if index == 3:
		update_options("crop",true)
		update_options("fit",true)


func update_options(option,value):
	if option == "fit":
		if value == true:
			expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if value == false:
			expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	if option == "crop":
		if value == true:
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if value == false:
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
