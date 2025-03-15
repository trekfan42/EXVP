@tool
extends Panel
class_name BoxHandle

@onready var parent_container: BoxContainer = self.get_parent()

@export var handleWidth: float = 5.0:
	set(value):
		handleWidth = value
		update_handle_width()

var parent_vertical: bool
var resizables := []
var dragging := false
var initial_mouse_pos := Vector2.ZERO
var initial_sizes := []
var total_size := 0.0
var handle_index := -1

func _ready():
	check_parent()
	update_handle_width()
	get_resizable_siblings()
	await get_tree().process_frame  # Ensure correct size after initialization
	calculate_stretch_ratios()  # Initialize stretch ratios dynamically

	# Determine which children this handle affects
	handle_index = int(get_index() / 2)  # Every other Control is a handle

func check_parent():
	if (parent_container is VBoxContainer) or (parent_container is BoxContainer and parent_container.vertical):
		parent_vertical = true
		mouse_default_cursor_shape = 9
	elif (parent_container is HBoxContainer) or (parent_container is BoxContainer and !parent_container.vertical):
		parent_vertical = false
		mouse_default_cursor_shape = 10
	else:
		print("HANDLE MUST BE CHILD OF BOXCONTAINER!")

func update_handle_width():
	if parent_vertical:
		self.custom_minimum_size = Vector2(0, handleWidth)
	else:
		self.custom_minimum_size = Vector2(handleWidth, 0)

func get_resizable_siblings():
	resizables.clear()
	for n in parent_container.get_children():
		if n is not BoxHandle:
			resizables.append(n)

func get_total_size() -> float:
	return parent_container.size.y if parent_vertical else parent_container.size.x

func calculate_stretch_ratios():
	""" Dynamically sets the stretch ratios of resizable children based on their actual sizes. """
	total_size = get_total_size()

	initial_sizes.clear()
	for r in resizables:
		var size = r.size.y if parent_vertical else r.size.x
		initial_sizes.append(size / total_size)  # Store size as percentage of total space

	# Apply these computed ratios to `size_flags_stretch_ratio`
	for i in range(resizables.size()):
		resizables[i].size_flags_stretch_ratio = snapped(initial_sizes[i], 0.001)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
		initial_mouse_pos = get_global_mouse_position()
		calculate_stretch_ratios()  # Ensure ratios are up-to-date before dragging

	elif event is InputEventMouseButton and !event.pressed:
		dragging = false

func _input(event):
	if dragging and event is InputEventMouseMotion:
		var current_mouse_pos = get_global_mouse_position()
		var delta_pos: float
		if parent_vertical:
			delta_pos = (current_mouse_pos.y - initial_mouse_pos.y)
		else:
			delta_pos = (current_mouse_pos.x - initial_mouse_pos.x)

		# Convert movement into percentage of total space
		var ratio_change = delta_pos / float(get_total_size())

		# Identify affected children
		var child_before = handle_index
		var child_after = handle_index + 1

		if child_after >= resizables.size():  # Prevent out-of-bounds errors
			return

		# Adjust ratios of only the two affected children
		var new_ratio_before = initial_sizes[child_before] + ratio_change
		var new_ratio_after = initial_sizes[child_after] - ratio_change

		# Apply new ratios to only the affected children
		resizables[child_before].size_flags_stretch_ratio = new_ratio_before
		resizables[child_after].size_flags_stretch_ratio = new_ratio_after
