extends Panel


func _ready():
	Signals.validation.connect(update)
	%SoftwareIdValue.text = Auth.shortId


func _on_help_codecs_button_up():
	hide_all()
	%HelpCodecText.show()

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




func _on_license_check_button_up():
	Auth.check_key(%LicenseEdit.text)


func update(status):
	if status == true:
		%LicenseStatus.visible = true
		%LicenseStatus.text = "Licensed: ✅\n\n"
		%Licensing.visible = false
		%TrialTimeLabel.visible = false
		%Trial.stop()
	else:
		%LicenseStatus.visible = true
		%LicenseStatus.text = "Invalid License!\n\n"
		%Licensing.visible = true
