extends Label



func _ready():
	pass
	if Auth.watermark:
		enable_watermark()
	Signals.watermarkEnable.connect(enable_watermark)

func enable_watermark():
	self.visible = true
