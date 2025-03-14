extends Window

var id = 0

func _ready():
	%Label.text = str(id+1)

func _on_timer_timeout():
	self.queue_free()
