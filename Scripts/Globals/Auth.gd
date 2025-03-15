extends Node

var shortId

var watermark = false

#To Be removed Licensing checks.
#To Be replaced with Gumroad Licensing?


func _ready():
	#date = Time.get_date_string_from_system() # YYYY-MM-DD
	#var uId = OS.get_unique_id()
	#shortId = uId.get_slice("-",0).get_slice("{",1) 
	#print("system Id: " + str(shortId))
	#var iT = 2
	#var iteration = shortId
	#
	#for i in iT:
		#iteration = Marshalls.utf8_to_base64(iteration)
	#print("Key file: " + str(iteration.get_slice("=",0)) + ".key")
	#
	#for i in iT:
		#iteration =  Marshalls.base64_to_utf8(iteration)
	#var id = iteration.get_slice("_",0)
	#print("decoded Id: " + id)
	
	pass


func check_key(entered_key):
	print("checking key...")
	
	if algorithm(entered_key) == shortId:
		print("validKey")
		Signals.validation.emit(true)
		save_key(entered_key)
	else:
		print("invalidKey")
		Signals.validation.emit(false)

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
