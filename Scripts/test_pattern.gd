extends Control


func _ready():
	if Global.testPattern:
		self.visible = true
		
	Signals.testPattern.connect(toggle_visibility)

func toggle_visibility(status):
	self.visible = status
