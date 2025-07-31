extends CharacterBody2D

@export var go = true
@export var steerSpeedRps:float = 3.0;
@export var speed:float = 250.0; # pixels per second

func _physics_process(delta: float) -> void:
	if not go:
		return
	
	var netSteer:float = 0.0
		
	if Input.is_action_pressed("ui_left"):
		netSteer -= steerSpeedRps * delta;
	if Input.is_action_pressed("ui_right"):
		netSteer += steerSpeedRps * delta;
		
	rotate(netSteer)
	
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	move_and_slide()
