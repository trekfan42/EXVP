@tool
extends TextureRect

signal generation_started
signal generation_progress(normalized_progress)
signal generation_completed

var voice_preview_generator
var stream : AudioStream = null
var stream_length := 0.0

@export_file("*.wav","*.mp3") var stream_path: String = "":
	set(new_path):
		stream_path = new_path
		_update_preview()

# Quality control exports
@export var max_frequency: float = 16000.0:
	set(new_max_frequency):
		max_frequency = new_max_frequency
		_update_preview()

@export var image_height: int = 128:
	set(new_image_height):
		image_height = new_image_height
		_update_preview()

@export var image_max_width: int = 2000:
	set(new_image_max_width):
		image_max_width = new_image_max_width
		_update_preview()

var image_compression: float = 2.0

func _ready():
	voice_preview_generator = preload("res://addons/audio_preview/voice_preview_generator.tscn").instantiate()
	add_child(voice_preview_generator)
	voice_preview_generator.generation_progress.connect(_on_generation_progress)
	voice_preview_generator.texture_ready.connect(_on_texture_ready)

	_update_preview()

func _update_preview():
	if not voice_preview_generator:
		return

	if stream_path in ["", "res://", "user://"]:
		texture = null
		return

	stream = load(stream_path)
	if stream is AudioStreamWAV:
		stream_length = stream.get_length()
	elif stream is AudioStreamMP3:
		stream_length = stream.get_length()
	else:
		stream_length = 0

	voice_preview_generator.generate_preview(stream, image_max_width, max_frequency, image_height, image_compression)
	emit_signal("generation_started")

func _on_generation_progress(normalized_progress: float):
	emit_signal("generation_progress", normalized_progress)

func _on_texture_ready(image_texture):
	texture = image_texture
	emit_signal("generation_completed")
