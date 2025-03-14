extends TextureRect

var picPath


func _ready():
	var pic = Image.load_from_file(picPath)
	var imageTexture = ImageTexture.new()
	imageTexture.set_image(pic)
	self.texture = imageTexture



func update_options(option,value):
	if option == "fit":
		if value == true:
			expand_mode = TextureRect.EXPAND_FIT_WIDTH
		if value == false:
			expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	if option == "crop":
		if value == true:
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if value == false:
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
