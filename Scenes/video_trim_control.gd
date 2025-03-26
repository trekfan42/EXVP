extends Panel

@onready var itemParent = $"../../../../../../../.."
@onready var parent_panel := %VideoTrimControl
@onready var start_handle := %StartTrimHandle
@onready var end_handle := %EndTrimHandle

var videoLength: float

var trim_ratio: float
var start_trim: int = 0
var end_trim: int

var dragging = null
var last_parent_width: float
var accumulated_movement: float = 0.0
var movement_threshold: float = 10.0  # Threshold in pixels before a snap step occurs

func _ready():
	start_handle.mouse_default_cursor_shape = 10
	end_handle.mouse_default_cursor_shape = 10

func setup_controls():
	videoLength = itemParent.itemData["length"]
	start_trim = itemParent.tempSettings["startPoint"]
	end_trim = itemParent.tempSettings["endPoint"]
	%StartTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["startPoint"])
	%EndTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["endPoint"])
	%EndTime.text = Utils.Secs_To_MMSS(itemParent.itemData["length"])
	last_parent_width = parent_panel.size.x
	position_handles()

func update_trim_ratio():
	print("Panel Width: " + str(parent_panel.size.x))
	trim_ratio = (parent_panel.size.x - (start_handle.size.x + end_handle.size.x)) / float(videoLength)
	print("Trim ratio: " + str(trim_ratio))

func position_handles():
	print(start_trim)
	print(end_trim)
	if int(start_trim) != 0:
		
		start_handle.position.x = start_trim * trim_ratio
		print("moving start handle to: ", str(start_handle.position.x))
	else:
		print("start handle to 0")
		start_handle.position.x = 0
	print("handle positions updated")
	
	if !itemParent.itemData["endPoint"]:
		end_trim = itemParent.itemData["length"]
		end_handle.position.x = parent_panel.size.x - end_handle.size.x 
	if itemParent.tempSettings["endPoint"]:
		end_trim = itemParent.tempSettings["endPoint"]
		end_handle.position.x = end_trim * trim_ratio + start_handle.size.x


func _process(_delta):
	if parent_panel.size.x != last_parent_width and itemParent.settingsPanel.visible:
		update_trim_ratio()
		position_handles()
		last_parent_width = parent_panel.size.x
	if itemParent.type == "video":
		if %TrimFill.position.x != start_handle.position.x + (start_handle.size.x / 2):
			%TrimFill.position.x = start_handle.position.x + (start_handle.size.x / 2)
		if %TrimFill.size.x != end_handle.position.x - start_handle.position.x:
			%TrimFill.size.x = end_handle.position.x - start_handle.position.x
	if itemParent.type == "audio":
		if %AudioMaskStart.size.x != start_handle.position.x:
			%AudioMaskStart.size.x = start_handle.position.x
		if %AudioMaskEnd.size.x != parent_panel.size.x - end_handle.position.x:
			%AudioMaskEnd.position.x = end_handle.position.x
			%AudioMaskEnd.size.x = parent_panel.size.x - end_handle.position.x

func _input(event):
	if event is InputEventMouseMotion and dragging:
		var start_handle_width = start_handle.size.x
		var end_handle_width = end_handle.size.x
		var snap_interval = 0

		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT):
			snap_interval = 60
		elif Input.is_key_pressed(KEY_SHIFT):
			snap_interval = 10
		elif Input.is_key_pressed(KEY_CTRL):
			snap_interval = 1

		if snap_interval > 0:
			accumulated_movement += event.relative.x
			if abs(accumulated_movement) >= movement_threshold:
				var snap_steps = int((accumulated_movement / movement_threshold) * snap_interval)
				accumulated_movement = 0.0  # Reset movement accumulation after applying a snap

				if dragging == "start":
					start_trim = clamp(start_trim + snap_steps, 0, end_trim - snap_interval)
					start_handle.position.x = start_trim * trim_ratio
					print("start trim: " + str(start_trim))
					itemParent.tempSettings["startPoint"] = start_trim
					%StartTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["startPoint"])
				
				elif dragging == "end":
					end_trim = clamp(end_trim + snap_steps, start_trim + snap_interval, videoLength)
					end_handle.position.x = end_trim * trim_ratio + start_handle.size.x
					print("end trim: " + str(end_trim))
					itemParent.tempSettings["endPoint"] = end_trim
					%EndTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["endPoint"])
		else:
			# Move smoothly without snapping when no modifier keys are pressed
			if dragging == "start":
				var new_x = clamp(start_handle.position.x + event.relative.x, 0, end_handle.position.x - end_handle_width)
				if start_handle.position.x < 0:
					start_handle.position.x = 0
				start_handle.position.x = new_x
				start_trim = int((new_x) / trim_ratio)
				itemParent.tempSettings["startPoint"] = start_trim
				%StartTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["startPoint"])
				
			elif dragging == "end":
				var new_x = clamp(end_handle.position.x + event.relative.x, start_handle.position.x + start_handle_width, parent_panel.size.x - end_handle_width)
				if end_handle.position.x > parent_panel.size.x:
					end_handle.position.x = parent_panel.size.x
				end_handle.position.x = new_x
				end_trim = int((new_x - start_handle_width) / trim_ratio)
				itemParent.tempSettings["endPoint"] = end_trim
				%EndTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["endPoint"])


func _on_start_trim_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = "start"
				accumulated_movement = 0.0
			if event.is_released():
				dragging = null
				itemParent.check_new_settings()
				position_handles()
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				print("reset start handle")
				start_trim = itemParent.itemData["startPoint"]
				itemParent.tempSettings["startPoint"] = start_trim
				itemParent.check_new_settings()
				position_handles()
				%StartTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["startPoint"])

func _on_end_trim_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = "end"
				accumulated_movement = 0.0
			if event.is_released():
				dragging = null
				itemParent.check_new_settings()
				position_handles()
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				print("reset end handle")
				end_trim = itemParent.itemData["endPoint"]
				itemParent.tempSettings["endPoint"] = end_trim
				itemParent.check_new_settings()
				position_handles()
				%EndTrimTime.text = Utils.Secs_To_MMSS(itemParent.tempSettings["endPoint"])
