class_name Car
extends CharacterBody2D

@export var go = true
@export var steerSpeedRps:float = 3.0;
@export var speed:float = 250.0; # pixels per second
@export var offRoadResist:float = 0.1
@export var minRotationDegreesForSmoothing:float = 0.5
@export var maxRotationDegreesForSmoothing:float = 45

@export var cameraSmoothingCurve:Curve
signal waypointSignal

var bCameraRotating = false

# used for outputing to waypoints
var steerIntent:float = 0.0 
@onready var netSpeed:float = speed

func _ready() -> void:
	pass


func ApplyCameraRotation(steerInput:float):
	var cameraNode:Camera2D = find_child("Camera2D")
	if not cameraNode:
		return
		
	var angleDifferenceDegrees = abs(angle_difference(cameraNode.get_viewport_transform().get_rotation(), global_rotation))

	var cameraSmoothingSpeed = 0.1
	if angleDifferenceDegrees >= minRotationDegreesForSmoothing:
		var percentDiff = clampf(angleDifferenceDegrees, minRotationDegreesForSmoothing, maxRotationDegreesForSmoothing)
		percentDiff = percentDiff - minRotationDegreesForSmoothing
		percentDiff = percentDiff / (maxRotationDegreesForSmoothing - minRotationDegreesForSmoothing)
		cameraSmoothingSpeed = cameraSmoothingCurve.sample(percentDiff)
		bCameraRotating = true
	elif bCameraRotating and angleDifferenceDegrees > 0.001:
		cameraSmoothingSpeed = cameraSmoothingCurve.sample(0)
		
	bCameraRotating = angleDifferenceDegrees > 0.001
	print("Camera Pos: ", cameraNode.position)
	cameraNode.rotation_smoothing_speed = cameraSmoothingSpeed
	cameraNode.position_smoothing_speed = cameraSmoothingSpeed
	
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
	ApplyCameraRotation(steerInput)
	
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
