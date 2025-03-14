extends Node


func Secs_To_MMSS(seconds):
	var minutes = seconds / 60
	var remainingSeconds = int(seconds) % 60
	var outputFormat = "%02d:%02d"
	var output = outputFormat % [floor(minutes) , round(remainingSeconds)]
	return output
