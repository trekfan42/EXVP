extends VBoxContainer


func _ready():
	pass
	#auth_validate()

func auth_validate():
	Signals.validation.connect(update)
	%SoftwareIdValue.text = Auth.shortId


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
