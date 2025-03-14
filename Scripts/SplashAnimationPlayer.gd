extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	%Splash.visible = true
	self.play("fade_out")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel") and %Splash.visible:
		%Splash.visible = false
	if Input.is_action_just_pressed("left_click") and %Splash.visible:
		%Splash.visible = false


func _on_animation_finished(_anim_name):
	%Splash.visible = false
