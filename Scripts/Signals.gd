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
signal deletePopup

signal slideshow

signal queueItem

signal sort

signal loadPics

signal changedResolution
var outputResolution = Vector2i(1920,1080):
	set(value):
		outputResolution = value
		print(outputResolution)
		changedResolution.emit()

var outputFPS: int = 60:
	set(value):
		outputFPS = value
		print(outputFPS)
		Engine.max_fps = outputFPS


var uiScale:float = 0.8:
	set(value):
		uiScale = value
		get_window().content_scale_factor = uiScale

var videoExts = ["mp4","MP4","m4v","M4V","mov","MOV","mkv","MKV"]
var picExts = ["jpeg","jpg","JPG","JPEG","png","PNG"]

signal slide
signal startSlides
signal pauseSlides
signal setSlide
signal updateSlideOptions

signal shuffleSlides

signal videoInfo
signal stopVideo
signal startVideo
signal loadVideo
signal pauseToggle
signal setPos
signal setVol
signal setAspect
signal setCrop
signal timeHover
signal Option

signal loadThumbs

signal removeItem

signal itemFinished
signal tcpStatus

signal videoExtended
signal testPattern

signal errorMsg

var showTips = true

var watermark = false
signal watermarkEnable

var shortId
var date 

signal setPlaybackEngine
var playbackEngine = FFmpegVideoStream

signal validation

func _ready():
	#date = Time.get_date_string_from_system() # YYYY-MM-DD
	var uId = OS.get_unique_id()
	shortId = uId.get_slice("-",0).get_slice("{",1) 
	print("system Id: " + str(shortId))
	var iT = 2
	var iteration = shortId
	
	for i in iT:
		iteration = Marshalls.utf8_to_base64(iteration)
	print("Key file: " + str(iteration.get_slice("=",0)) + ".key")
	
	for i in iT:
		iteration =  Marshalls.base64_to_utf8(iteration)
	var id = iteration.get_slice("_",0)
	print("decoded Id: " + id)


func check_key(entered_key):
	print("checking key...")
	
	if algorithm(entered_key) == shortId:
		print("validKey")
		validation.emit(true)
		save_key(entered_key)
	else:
		print("invalidKey")
		validation.emit(false)

func algorithm(entered_key):
	for i in 2:
		entered_key = Marshalls.base64_to_utf8(entered_key)
	var decodedKey = entered_key
	return decodedKey


func check_saved_key():
	var home = OS.get_executable_path().get_base_dir()
	var files
	files = DirAccess.get_files_at(home)
	var keyExt = ".key"
	for f in files:
		var ext = "." + f.get_extension()
		if ext == keyExt:
			check_key(f.get_slice(ext,0))


func save_key(validKey):
	var savePath = str(OS.get_executable_path().get_base_dir()) + "/" + validKey + ".key"
	var file = FileAccess.open(savePath, FileAccess.WRITE)
	file.close()
	print("key file stored: " + savePath)
