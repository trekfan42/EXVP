@tool
extends Label

const SLIDER_WARNING = "SliderLabel needs to be a child of a Slider control (HSlider or VSlider)."
const SLIDER_WARNING2 = "custom_slider_path needs to point to a valid Slider control (HSlider or VSlider)."

enum VisibilityRule {ON_CLICK, ON_HOVER, ON_FOCUS, ALWAYS}
enum Placement {TOP_RIGHT, BOTTOM_LEFT}

@export var visibility_rule: VisibilityRule = VisibilityRule.ON_HOVER
@export var placement: Placement = Placement.TOP_RIGHT
@export var separation := 4
@export var custom_format := ""
@export_node_path("Slider") var custom_slider_path = NodePath():
	set(path):
		custom_slider_path = path
		update_configuration_warnings()

var slider: Slider
var vertical: bool

var slideId = null

func _enter_tree() -> void:
	if not has_meta(&"_edit_initialized_"):
		set_meta(&"_edit_initialized_", true)
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		size_flags_horizontal = SIZE_SHRINK_CENTER
		text = "100"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if custom_slider_path.is_empty():
		slider = get_parent() as Slider
		assert(slider != null, SLIDER_WARNING)
	else:
		slider = get_node(custom_slider_path) as Slider
		assert(slider != null, SLIDER_WARNING2)
	
	if slider is VSlider:
		vertical = true
	
	slider.value_changed.connect(update_with_discard)
	
	if visibility_rule == VisibilityRule.ALWAYS:
		show()
	else:
		hide()
		
		match visibility_rule:
			VisibilityRule.ON_CLICK:
				slider.gui_input.connect(_on_slider_gui_input)
			VisibilityRule.ON_HOVER:
				slider.mouse_entered.connect(_on_slider_hover_focus.bind(true))
				slider.mouse_exited.connect(_on_slider_hover_focus.bind(false))
			VisibilityRule.ON_FOCUS:
				slider.focus_entered.connect(_on_slider_hover_focus.bind(true))
				slider.focus_exited.connect(_on_slider_hover_focus.bind(false))
	update_label()



func _on_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = event.pressed
		update_label()

func _on_slider_hover_focus(hover: bool):
	visible = hover
	#if self.get_parent().name != "Volume":
		#Signals.timeHover.emit(hover)
	update_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		update_configuration_warnings()

func update_with_discard(discard):
	update_label()

func update_label():
	if not is_visible_in_tree():
		return
	
	if custom_format.is_empty():
		if self.get_parent().name != "Volume":
			if Global.activeType == "video":
				text = secondsToMMSS(slider.value)
			if Global.activeType == "slideshow":
				text = str(slider.value)
		else:
			text = str(slider.value) + " dB"
	else:
		text = custom_format % slider.value
	
	hide()
	show()
	size = Vector2()
	
	var grabber_size := slider.get_theme_icon(&"Grabber").get_size()
	if vertical:
		position.y = (1.0 - slider.ratio) * (slider.size.y - grabber_size.y) + grabber_size.y * 0.5 - size.y * 0.5
		if placement == Placement.TOP_RIGHT:
			position.x = slider.size.x + separation
		else:
			position.x = -size.x - separation
	else:
		position.x = slider.ratio * (slider.size.x - grabber_size.x) + grabber_size.x * 0.5 - size.x * 0.5
		if placement == Placement.TOP_RIGHT:
			position.y = -size.y - separation
		else:
			position.y = slider.size.y + separation

func _get_configuration_warnings() -> PackedStringArray:
	var ret: PackedStringArray
	
	if custom_slider_path.is_empty():
		if not get_parent() is Slider:
			ret.append(SLIDER_WARNING)
	else:
		if not get_node(custom_slider_path) is Slider:
			ret.append(SLIDER_WARNING2)
	
	return ret


func secondsToMMSS(seconds):
	var minutes = seconds / 60
	var remainingSeconds = int(seconds) % 60
	var outputFormat = "%02d:%02d"
	var output = outputFormat % [floor(minutes) , round(remainingSeconds)]
	return output
