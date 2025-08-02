class_name Car
extends CharacterBody2D

@export var go = true
@export var steerSpeedRps:float = 3.0;
@export var speed:float = 900.0; # pixels per second
@export var offRoadResist:float = 0.15
@export var lapAcceleration:float = 0.05 # multiplier per lap completed
@export var oilSlowdown:float = 0.5

var lapsCompleted = 0

signal waypointSignal

var explosionScene = preload("res://car/CarExplosion.tscn")

# used for outputing to waypoints
var steerIntent:float = 0.0 
@onready var netSpeed:float = speed

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if not go:
		$DriveSound.playing = false
		$TurnSound.playing = false
		return
	if $DriveSound.playing == false:
		$DriveSound.play()
	
	var isOilInEffect = not $OilEffectTimer.is_stopped()
	var oilFactor:float = oilSlowdown if isOilInEffect else 1.0
			
	var steerInput:float = 0.0
	var inputChanged:bool = false
		
	if Input.is_action_pressed("ui_left"):
		steerInput -= steerSpeedRps;
	if Input.is_action_pressed("ui_right"):
		steerInput += steerSpeedRps;
		
	if isOilInEffect:
		const inertia:float = 0.9
		steerInput = steerIntent*inertia + steerInput*(1-inertia) # oil locks you into your previous steering input
			
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
	
	var lapFactor = 1 + lapsCompleted * lapAcceleration
	var effectiveSpeed = speed * tiresOnTrack * lapFactor * oilFactor
	if effectiveSpeed != netSpeed:
		inputChanged = true
		
	velocity = Vector2.RIGHT.rotated(rotation) * effectiveSpeed
	
	move_and_slide()
	
	if inputChanged:
		waypointSignal.emit()


func _on_turn_sound_delay_timeout() -> void:
	if($TurnSound.playing == false):
		$TurnSound.play()


func _on_hit_box_2d_body_entered(_body: Node2D) -> void:
	#TODO do we want to allow power-ups, or just die?
	doExplosion()

func doExplosion() -> void:
	go = false
	$HitBox2D/HB_Collider.set_deferred("disabled", true)
	$PhysicsCollider.set_deferred("disabled", true)
	$Sprite2D.visible = false

	var game:Game = get_parent()
	var explosion:CarExplosion = explosionScene.instantiate()
	explosion.position = position
	explosion.rotation = rotation
	game.add_child(explosion)
	
	game.doGameOver()

func revive() -> void:
	$HitBox2D/HB_Collider.set_deferred("disabled", false)
	$PhysicsCollider.set_deferred("disabled", false)
	steerIntent = 0.0
	lapsCompleted = 0
	$TurnSoundDelay.stop()
	if($DriveSound.playing == true):
		$DriveSound.stop()
	if($TurnSound.playing == true):
		$TurnSound.stop()
	$Sprite2D.visible = true
	
func applyOil() -> void:
	$OilEffectTimer.start()
