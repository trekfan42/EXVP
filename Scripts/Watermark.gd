extends Label



func _ready():
	if Signals.watermark:
		enable_watermark()
	Signals.watermarkEnable.connect(enable_watermark)

func enable_watermark():
	self.visible = true

	#customHash("davisam42@gmail.com")
	#customHash("buttboy@mail.com")
#
#
#func customHash(input):
	#var inputText = input.get_slice("@",0) + str(42)
	#var hashValue = inputText.md5_text()
	#print(inputText)
	#print(hashValue)
#
	#var inputText1 = input.to_utf8_buffer().hex_encode()
	#print(inputText1)
	#print(inputText1.hex_decode().get_string_from_utf8())
