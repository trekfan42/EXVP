@tool
extends Node

signal texture_ready(texture)
signal generation_progress(normalized_progress)

var foreground_color = Color.WHITE

var is_working := false
var must_abort := false

func generate_preview(stream, image_max_width: int, max_frequency: float, image_height: int, image_compression: float):
	if not stream:
		return

	var data: PackedByteArray
	var mix_rate: float
	var is_16bit: bool
	var is_stereo: bool

	if stream is AudioStreamWAV:
		if stream.format == AudioStreamWAV.FORMAT_IMA_ADPCM:
			return # not supported
		data = stream.data
		mix_rate = stream.mix_rate
		is_16bit = (stream.format == AudioStreamWAV.FORMAT_16_BITS)
		is_stereo = stream.stereo

	elif stream is AudioStreamMP3:
		data = stream.data
		mix_rate = 44100.0 # Default mix rate (common for MP3)
		is_16bit = true # MP3 is decoded to 16-bit PCM
		is_stereo = true # Assume stereo

	else:
		return # unsupported stream type

	if image_max_width <= 0:
		return # User wasn't remarkably brilliant

	if is_working:
		must_abort = true
		while is_working:
			await get_tree().process_frame

	is_working = true

	var sampling_rate: float = 2.0 * max_frequency
	var image_height_factor: float = float(image_height) / 128.0
	var image_center_y: int = int(round(image_height / 2.0))

	var data_size = data.size()

	var sample_interval = 1
	if mix_rate > sampling_rate:
		sample_interval = int(round(mix_rate / sampling_rate))
	if is_16bit:
		sample_interval *= 2
	if is_stereo:
		sample_interval *= 2

	var reduced_data = PackedByteArray()
	var reduced_data_size = int(floor(data_size / float(sample_interval)))
	reduced_data.resize(reduced_data_size)

	var sample_in_i := 1 if is_16bit else 0
	var sample_out_i := 0
	while (sample_in_i < data_size) and (sample_out_i < reduced_data_size):
		reduced_data[sample_out_i] = data[sample_in_i]

		sample_in_i += sample_interval
		sample_out_i += 1

		if must_abort:
			is_working = false
			must_abort = false
			return

	image_compression = ceil(reduced_data_size / float(image_max_width))

	var img_width = floor(reduced_data_size / image_compression)
	var img = Image.create(img_width, image_height, true, Image.FORMAT_RGBA8)

	# Fill with transparent black
	var transparent_black = Color(0, 0, 0, 0) # RGBA: Red, Green, Blue, Alpha
	img.fill(transparent_black)

	var sample_i = 0
	var img_x = 0
	var final_sample_i = (reduced_data_size - image_compression)

	# Normalization
	var max_abs_sample: int = 0
	for i in range(reduced_data_size):
		var sample_val = reduced_data[i] - 128 # Convert to signed
		max_abs_sample = max(max_abs_sample, abs(sample_val))

	var normalization_factor: float = 1.0
	if max_abs_sample > 127:
		normalization_factor = 127.0 / float(max_abs_sample)

	while sample_i < final_sample_i:
		var min_val := 128
		var max_val := 128
		for block_i in range(image_compression):
			var sample_val = reduced_data[sample_i]
			sample_val += 128
			if sample_val >= 256:
				sample_val -= 256

			# Normalize samples
			sample_val = int(round((sample_val - 128) * normalization_factor)) + 128

			if sample_val < min_val:
				min_val = sample_val
			if sample_val > max_val:
				max_val = sample_val

			sample_i += 1

		if (min_val == 128) and (max_val == 128):
			img.set_pixel(img_x, image_center_y, foreground_color)

		else:
			var min_height = int(floor(image_center_y - ((128 - min_val) * float(image_height) / 128.0)))
			var max_height = int(floor(image_center_y + ((max_val - 128) * float(image_height) / 128.0)))

			min_height = max(0, min_height)
			max_height = min(image_height - 1, max_height)

			if max_height > min_height:
				var img_y = min_height
				while img_y <= max_height:
					img.set_pixel(img_x, img_y, foreground_color)
					img_y += 1

		img_x += 1

		if must_abort:
			is_working = false
			must_abort = false
			return

		if (sample_i % 100) == 0:
			var progress = sample_i / final_sample_i
			emit_signal("generation_progress", progress)
			await get_tree().process_frame

	is_working = false

	emit_signal("texture_ready", ImageTexture.create_from_image(img))
