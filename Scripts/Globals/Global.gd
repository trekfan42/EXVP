extends Node

var app

var loop = false
var auto = false

var activeIndex = null
var activeItem = null
var activeType = null
var slideshowRunning = false
var activeSlide = null

var playIcon = true

var deleteReady = false

var showTips = true

var date

var playbackEngine = FFmpegVideoStream

var testPattern = false

var outputResolution = Vector2i(1920,1080):
	set(value):
		outputResolution = value
		print(outputResolution)
		Signals.changedResolution.emit()

var outputFPS: int = 60:
	set(value):
		outputFPS = value
		print(outputFPS)
		Engine.max_fps = outputFPS


var uiScale:float = 0.8:
	set(value):
		uiScale = value
		get_window().content_scale_factor = uiScale


var defaultBG = "res://UI/AppBG.jpg"
var bgImage: Image:
	set(value):
		bgImage = value
		Signals.changedBG.emit()

var videoExts = ["mp4","MP4","m4v","M4V","mov","MOV","mkv","MKV","webm","WEBM"]
var picExts = ["jpeg","jpg","JPG","JPEG","png","PNG","webp","WEBP","svg","SVG"]
