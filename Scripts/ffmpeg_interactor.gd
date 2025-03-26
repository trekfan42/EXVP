class FFmpegInteractor:
	# Path to the ffmpeg executable.  Set this when you create an instance of the class.
	var ffmpeg_path: String

	# Constructor.  You MUST provide the path to ffmpeg.exe.
	func _init(ffmpeg_path: String):
		self.ffmpeg_path = ffmpeg_path
		if !FileAccess.file_exists(ffmpeg_path):
			push_error("FFmpegInteractor: ffmpeg_path is invalid: " + ffmpeg_path)
			# Consider throwing an error here if FFmpeg is essential.

	# Method to execute an FFmpeg command and return the output.
	# command: An array of strings representing the FFmpeg command.
	# Returns:
	#   - On success: A Dictionary with:
	#     {
	#       "success": true,
	#       "output":  PackedStringArray, # Output lines from FFmpeg (stdout)
	#       "error":   PackedStringArray  # Error lines from FFmpeg (stderr)
	#     }
	#   - On failure: A Dictionary with:
	#     {
	#       "success": false,
	#       "error_code": int,         # The error code from OS.execute()
	#       "error":      PackedStringArray  # Error lines from FFmpeg (stderr)
	#     }
	func execute_command(command: PackedStringArray) -> Dictionary:
		if ffmpeg_path == "" or !FileAccess.file_exists(ffmpeg_path):
			return {
				"success": false,
				"error_code": -1,
				"error": ["FFmpeg path is not set or invalid."]
			}

		var full_command = PackedStringArray([ffmpeg_path]) + command  # Prepend ffmpeg_path
		print("FFmpegInteractor: Executing command: ", full_command) #debugging

		var output_array = []
		var read_stderr = true
		var open_console = false
		var exit_code = OS.execute(full_command, output_array, read_stderr, open_console)

		var output = PackedStringArray()
		var error_output = PackedStringArray()

		for line in output_array:
			if "ERROR:" in line:
				error_output.append(line)
			else:
				output.append(line)

		if exit_code == 0:
			return {
				"success": true,
				"output": output,
				"error":  error_output
			}
		else:
			return {
				"success": false,
				"error_code": exit_code,
				"error":  error_output
			}

	# Method to extract an AudioStream from a video file using FFmpeg.
	# video_file_path: The path to the video file.
	# Returns:
	#   - On success: An AudioStreamWAV object.
	#   - On failure: null.
	func get_audio_stream(video_file_path: String) -> AudioStream:
		if !FileAccess.file_exists(video_file_path):
			push_error("FFmpegInteractor: Video file does not exist: " + video_file_path)
			return null

		var temp_wav_path = "user://temp_audio_" + str(hash(video_file_path)) + ".wav" # Unique temp file name

		var ffmpeg_command = PackedStringArray([
			"-y",  # Overwrite existing file
			"-i", video_file_path,
			"-vn",
			"-acodec", "pcm_s16le",
			"-ar", "44100",
			"-ac", "2",
			temp_wav_path
		])

		var result = execute_command(ffmpeg_command) #use the function

		if not result.success:
			printerr("FFmpegInteractor: Failed to extract audio: ", result.error)
			return null

		var audio_stream_wav = AudioStreamWAV.new()
		var file_access = FileAccess.open(temp_wav_path, FileAccess.READ)
		if file_access:
			audio_stream_wav.data = file_access.get_buffer(file_access.get_length())
			file_access.close()
		else:
			printerr("FFmpegInteractor: Could not open temporary WAV file.")
			return null

		# Clean up the temporary file
		DirAccess.remove_absolute(temp_wav_path)
		return audio_stream_wav

	# Method to extract a frame from a video file and return it as an ImageTexture.
	# video_file_path: The path to the video file.
	# time: The time in seconds of the frame to extract.
	# Returns:
	#   - On success: An ImageTexture.
	#   - On failure: null.
	func get_video_frame(video_file_path: String, time: float) -> ImageTexture:
		if !FileAccess.file_exists(video_file_path):
			push_error("FFmpegInteractor: Video file does not exist: " + video_file_path)
			return null

		var temp_png_path = "user://temp_frame_" + str(hash(video_file_path + str(time))) + ".png"

		var ffmpeg_command = PackedStringArray([
			"-y",  # Overwrite output file if it exists
			"-i", video_file_path,
			"-ss", str(time),  # Seek to the specified time
			"-vframes", "1",  # Extract only one frame
			temp_png_path
		])

		var result = execute_command(ffmpeg_command)
		if not result.success:
			printerr("FFmpegInteractor: Failed to extract frame: ", result.error)
			return null

		# Load the image
		var image = Image.new()
		var load_result = image.load(temp_png_path)
		if load_result != OK:
			printerr("FFmpegInteractor: Failed to load image from temp file.")
			DirAccess.remove_absolute(temp_png_path)
			return null

		var texture = ImageTexture.create_from_image(image)
		DirAccess.remove_absolute(temp_png_path) #remove temp file
		return texture
