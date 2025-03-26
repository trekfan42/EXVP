extends Control

@export var line_color: Color = Color.AQUAMARINE
@export var line_width: int = 2
@export var max_frequency: float = 22050.0

@export var audio_stream: AudioStream = null:
	set(value):
		audio_stream = value
		_start_audio_processing_thread()

# Private variables
var min_peaks: PackedVector2Array = PackedVector2Array()
var max_peaks: PackedVector2Array = PackedVector2Array()
var cached_width: int = 0
var processing_thread: Thread = null
var thread_active: bool = false
var processed_data: Dictionary  # Stores results from the thread

signal audio_processed

func _ready():
	resized.connect(_on_resized)
	audio_processed.connect(_on_audio_processed)

	if audio_stream != null:
		_start_audio_processing_thread()

func _start_audio_processing_thread():
	if processing_thread and processing_thread.is_started():
		# Prevent multiple threads from running
		return
	
	processing_thread = Thread.new()
	thread_active = true
	processing_thread.start(_threaded_process_audio)

func _threaded_process_audio():
	# Process waveform data in a separate thread
	var min_peaks_thread = PackedVector2Array()
	var max_peaks_thread = PackedVector2Array()
	
	if audio_stream == null:
		thread_active = false
		return

	# Get audio data based on stream type
	var data: PackedByteArray
	var mix_rate: float
	var is_16bit: bool
	var is_stereo: bool
	
	if audio_stream is AudioStreamWAV:
		if audio_stream.format == AudioStreamWAV.FORMAT_IMA_ADPCM:
			push_error("IMA ADPCM format not supported for visualization")
			thread_active = false
			return
			
		data = audio_stream.data
		mix_rate = audio_stream.mix_rate
		is_16bit = (audio_stream.format == AudioStreamWAV.FORMAT_16_BITS)
		is_stereo = audio_stream.stereo
		
	elif audio_stream is AudioStreamMP3:
		data = audio_stream.data
		mix_rate = 44100.0
		is_16bit = true
		is_stereo = true
		
	else:
		push_error("Unsupported audio format")
		thread_active = false
		return

	# Process raw audio data
	var sampling_rate: float = 2.0 * max_frequency
	var data_size = data.size()
	
	# Calculate sample interval
	var sample_interval = 1
	if mix_rate > sampling_rate:
		sample_interval = int(round(mix_rate / sampling_rate))
	if is_16bit:
		sample_interval *= 2
	if is_stereo:
		sample_interval *= 2
	
	# Reduce data based on sample interval
	var reduced_data = PackedByteArray()
	var reduced_data_size = int(floor(data_size / float(sample_interval)))
	reduced_data.resize(reduced_data_size)
	
	var sample_in_i := 1 if is_16bit else 0
	var sample_out_i := 0
	
	while (sample_in_i < data_size) and (sample_out_i < reduced_data_size):
		reduced_data[sample_out_i] = data[sample_in_i]
		sample_in_i += sample_interval
		sample_out_i += 1
	
	# Extract waveform data
	var full_sample_count = 1000
	var compression = ceil(reduced_data_size / float(full_sample_count))
	
	# Normalize samples
	var max_abs_sample: int = 0
	for i in range(reduced_data_size):
		var sample_val = reduced_data[i] - 128
		max_abs_sample = max(max_abs_sample, abs(sample_val))

	max_abs_sample = max(max_abs_sample, 16)

	# Adjust amplitude scaling dynamically
	var amplitude_scale = 3.0
	if max_abs_sample < 64:
		amplitude_scale *= 1.5
	elif max_abs_sample < 32:
		amplitude_scale *= 2.0

	# Extract peak data
	var sample_i = 0
	while sample_i < reduced_data_size:
		var min_val := 128
		var max_val := 128

		for block_i in range(compression):
			if sample_i + block_i >= reduced_data_size:
				break

			var sample_val = reduced_data[sample_i + block_i]
			
			sample_val += 128
			if sample_val >= 256:
				sample_val -= 256

			sample_val = int(round((sample_val - 128) * (127.0 / float(max_abs_sample)))) + 128

			if sample_val < min_val:
				min_val = sample_val
			if sample_val > max_val:
				max_val = sample_val

		var min_height = 0.5 - ((128 - min_val) / 64.0) * amplitude_scale
		var max_height = 0.5 + ((max_val - 128) / 64.0) * amplitude_scale
		min_height = clamp(min_height, 0.05, 0.95)
		max_height = clamp(max_height, 0.05, 0.95)

		min_peaks_thread.append(Vector2(float(sample_i) / reduced_data_size, min_height))
		max_peaks_thread.append(Vector2(float(sample_i) / reduced_data_size, max_height))

		sample_i += compression

	# Store processed data and emit signal
	processed_data = {
		"min_peaks": min_peaks_thread,
		"max_peaks": max_peaks_thread
	}
	call_deferred("_emit_audio_processed")

	thread_active = false

func _emit_audio_processed():
	audio_processed.emit()

func _on_audio_processed():
	# This function is called in the main thread when processing is complete
	if processed_data.has("min_peaks") and processed_data.has("max_peaks"):
		min_peaks = processed_data["min_peaks"]
		max_peaks = processed_data["max_peaks"]
		queue_redraw()

	if processing_thread:
		processing_thread.wait_to_finish()
		processing_thread = null

func _draw():
	if min_peaks.size() < 2:
		return
	
	# **Dynamically adjust rendering based on width**
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
