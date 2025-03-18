extends MarginContainer

func _ready():
	_on_help_playlist_button_up()

func _on_help_videos_button_up():
	hide_all()
	%HelpVideosText.show()

func _on_help_trim_button_up():
	hide_all()
	%HelpTrimText.show()

func _on_help_slideshows_button_up():
	hide_all()
	%HelpSlideshows.show()

func _on_help_shortcuts_button_up():
	hide_all()
	%HelpShortcuts.show()

func _on_help_playlist_button_up():
	hide_all()
	%HelpPlaylistText.show()

func _on_help_companion_button_up():
	hide_all()
	%HelpCompanionText.show()

func hide_all():
	for t in %HelpTexts.get_children():
		t.visible = false
