extends TextureRect

var id
var picTex
var overriden = false

func _ready():
	self.texture = picTex
	Signals.setSlide.connect(override)
	pivot_offset.x = size.x/2
	pivot_offset.y = size.y/2
	

func override(_id,_quiet):
	overriden = true


func fade_in(fadeTime):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, fadeTime)
	tween.connect("finished",fade_in_finished)

func fade_in_finished():
	pass
	if !overriden:
		self.get_parent().start_hold()

func fade_out(fadeTime):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color.TRANSPARENT, fadeTime)
	tween.connect("finished",queue_free)

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
