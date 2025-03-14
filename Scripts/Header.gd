extends HBoxContainer

var following = false
var dragging_start_position = Vector2()

var mode = 0

func _on_TitleBar_gui_input(event):
	if event is InputEventMouseButton:
		if event.get_button_index() == 1:
			following = !following
			dragging_start_position = get_local_mouse_position()

func _process(_delta):
	if following:
		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(get_global_mouse_position() - dragging_start_position))


func _on_quit_button_button_up():
	get_tree().quit()


func _on_max_button_button_up():
	if mode == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_min_button_button_up():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)  
