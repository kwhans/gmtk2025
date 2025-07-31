extends CharacterBody2D

@export var go = true
@export var steerSpeedRps:float = 3.0;
@export var speed:float = 250.0; # pixels per second

func _physics_process(delta: float) -> void:
	if not go:
		$DriveSound.playing = false
		return
	if $DriveSound.playing == false:
		$DriveSound.play()
		
	var steerInput:float = 0.0
		
	if Input.is_action_pressed("ui_left"):
		steerInput -= steerSpeedRps;
	if Input.is_action_pressed("ui_right"):
		steerInput += steerSpeedRps;
		
	rotate(steerInput*delta)
	
	if(abs(steerInput) > 1.0 and $TurnSound.playing == false):
		$TurnSound.play()
	
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	move_and_slide()
