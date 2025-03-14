@tool
extends Control
class_name BoxHandle


@onready var parent_container = self.get_parent()
@export var handle_size: int = 5:
	set(value):
		handle_size = value
		set_handle_size()

@export var handle_color: Color = Color(0.3, 0.3, 0.3, 1):
	set(value):
		handle_color = value
		if Engine.is_editor_hint():  # Ensure it updates in the editor
			queue_redraw()


var panels := []
var dragging := false
var initial_mouse_pos := Vector2.ZERO
var initial_ratios := []
var total_size := 0.0
var handle_index := -1
var last_mouse_pos

func _ready():
	set_handle_size()
	
	await get_tree().process_frame  # Ensure correct size after initialization
	total_size = parent_container.size.y if parent_container is VBoxContainer else parent_container.size.x

	# Detect panels dynamically, but EXCLUDE handles based on name
	for i in range(parent_container.get_child_count()):
		var child = parent_container.get_child(i)
		
		# If name contains "handle", it's ignored; otherwise, it's a panel
		if not child is BoxHandle:
			panels.append(child)

	# Determine which panels this handle affects
	handle_index = int(get_index() / 2)  # Every other Control is a handle

func set_handle_size():
	if parent_container is VBoxContainer:
		self.custom_minimum_size = Vector2(0,handle_size)
	else:
		self.custom_minimum_size = Vector2(handle_size,0)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), handle_color, true)  # Fills the control

func _on_theme_changed():
	queue_redraw()  # Redraw if theme changes


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true

		# Convert global mouse position to local space relative to the parent container
		var container_pos = parent_container.global_position
		initial_mouse_pos = get_global_mouse_position() - container_pos  # Set initial mouse position
		last_mouse_pos = initial_mouse_pos  # 🔥 Track last mouse position for per-frame delta

		# Store initial ratios of all panels
		initial_ratios.clear()
		for panel in panels:
			initial_ratios.append(panel.size_flags_stretch_ratio)

	elif event is InputEventMouseButton and !event.pressed:
		dragging = false






func _process(_delta):
	if !dragging:
		return  # Stop processing if not dragging

	# Get the parent container's position in global space
	var container_pos = parent_container.global_position

	# Get the current mouse position, relative to the parent container
	var current_mouse_pos = get_global_mouse_position() - container_pos

	# 🔥 Track only per-frame mouse movement
	var frame_delta = (current_mouse_pos.y - last_mouse_pos.y) if parent_container is VBoxContainer else (current_mouse_pos.x - last_mouse_pos.x)

	# Get total pixel size of the container
	var total_pixel_size = parent_container.size.y if parent_container is VBoxContainer else parent_container.size.x

	# Identify affected panels
	var panel_before = handle_index
	var panel_after = handle_index + 1

	if panel_after >= panels.size():
		return  # Prevent out-of-bounds errors

	# 🔥 Convert ratio change into actual pixel change
	var total_stretch = panels[panel_before].size_flags_stretch_ratio + panels[panel_after].size_flags_stretch_ratio
	var total_panel_pixel_size = panels[panel_before].size.y + panels[panel_after].size.y if parent_container is VBoxContainer else panels[panel_before].size.x + panels[panel_after].size.x
	var pixel_ratio = total_stretch / total_panel_pixel_size  # Convert pixels back to stretch space
	# 🔥 Modify panel sizes directly
	if parent_container is VBoxContainer:
		panels[panel_before].size.y += frame_delta
		panels[panel_after].size.y -= frame_delta
	else:
		panels[panel_before].size.x += frame_delta
		panels[panel_after].size.x -= frame_delta

	# 🔥 Convert back to stretch ratio to maintain proper resizing logic
	panels[panel_before].size_flags_stretch_ratio = max(0.05, (panels[panel_before].size.y * pixel_ratio)) if parent_container is VBoxContainer else max(0.05, (panels[panel_before].size.x * pixel_ratio))
	panels[panel_after].size_flags_stretch_ratio = max(0.05, (panels[panel_after].size.y * pixel_ratio)) if parent_container is VBoxContainer else max(0.05, (panels[panel_after].size.x * pixel_ratio))

	# 🔥 Now update `last_mouse_pos` to track only per-frame movement
	last_mouse_pos = current_mouse_pos
