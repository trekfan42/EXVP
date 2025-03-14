extends Control

func _ready():
	Signals.deletePopup.connect(visibility)

func visibility(status):
	if status:
		open()
	else:
		close()

func open():
	%Area2D.monitorable = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size:y" , 100 , 0.5).set_trans(Tween.TRANS_EXPO)

	
func close():
	%Area2D.monitorable = false
	var tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size:y" , 0 , 0.5).set_trans(Tween.TRANS_EXPO)

func _on_area_2d_area_entered(area):
	Global.deleteReady = true
	print("delete ready")


func _on_area_2d_area_exited(area):
	Global.deleteReady = false
	print("delete cancelled")
