class_name Car
extends CharacterBody2D

@export var go = true
@export var steerSpeedRps:float = 3.0;
@export var speed:float = 250.0; # pixels per second
@export var offRoadResist:float = 0.1
signal waypointSignal

# used for outputing to waypoints
var steerIntent:float = 0.0 
@onready var netSpeed:float = speed

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if not go:
		$DriveSound.playing = false
		return
	if $DriveSound.playing == false:
		$DriveSound.play()
		
	var steerInput:float = 0.0
	var inputChanged:bool = false
		
	if Input.is_action_pressed("ui_left"):
		steerInput -= steerSpeedRps;
	if Input.is_action_pressed("ui_right"):
		steerInput += steerSpeedRps;
		
	if steerIntent != steerInput:
		inputChanged = true
		
	steerIntent = steerInput
	
	rotate(steerInput*delta)
	
	if(abs(steerInput) > 1.0):
		if($TurnSound.playing == false && $TurnSoundDelay.is_stopped()):
			$TurnSoundDelay.start()
	else:
		$TurnSound.playing = false
		$TurnSoundDelay.stop()
	
#	count tires touching road to affect speed
	var tiresOnTrack:float = 1.0
	if $Tire1.has_overlapping_bodies() == false:
		tiresOnTrack -= offRoadResist
	if $Tire2.has_overlapping_bodies() == false:
		tiresOnTrack -= offRoadResist
	if $Tire3.has_overlapping_bodies() == false:
		tiresOnTrack -= offRoadResist
	if $Tire4.has_overlapping_bodies() == false:
		tiresOnTrack -= offRoadResist
	
	var effectiveSpeed = speed * tiresOnTrack
	if effectiveSpeed != netSpeed:
		inputChanged = true
		
	velocity = Vector2.RIGHT.rotated(rotation) * effectiveSpeed
	
	move_and_slide()
	
	if inputChanged:
		waypointSignal.emit()


func _on_turn_sound_delay_timeout() -> void:
	if($TurnSound.playing == false):
			$TurnSound.play()
