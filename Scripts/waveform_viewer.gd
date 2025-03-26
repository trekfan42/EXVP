extends Control

@export var line_color: Color = Color.AQUAMARINE
@export var line_width: int = 2

# Storage for waveform peak data
var min_peaks: PackedVector2Array = PackedVector2Array()
var max_peaks: PackedVector2Array = PackedVector2Array()

# Setter to update peak data from another script
func set_peak_data(new_min_peaks: PackedVector2Array, new_max_peaks: PackedVector2Array):
	min_peaks = new_min_peaks
	max_peaks = new_max_peaks
	queue_redraw()  # Redraw after updating the data

func _draw():
	if min_peaks.size() < 2:
		return
	
	
	# Dynamically adjust rendering based on width
	var min_spacing = 3  # Minimum pixel spacing
	var render_sample_count = max(20, int(self.size.x / min_spacing / 3))  
	render_sample_count = min(render_sample_count, min_peaks.size())  

	# Select evenly spaced samples from precomputed waveform
	var step = max(1, min_peaks.size() / render_sample_count)

	for i in range(render_sample_count):
		var index = int(i * step)
		var x = float(i) / render_sample_count * self.size.x
		var y_min = min_peaks[index].y * self.size.y
		var y_max = max_peaks[index].y * self.size.y

		draw_line(Vector2(x, y_min), Vector2(x, y_max), line_color, line_width)

func _on_resized():
	queue_redraw()
