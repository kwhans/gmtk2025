class_name GhostCar
extends CharacterBody2D

var nextWaypoint:Waypoint = null
var nextWaypointIdx:int = 0
var millisAtStart:int = 0 # ms timestame that this car started
var timeSkipMillis:int = 0 # ms ticks to skip forward so that we can skip to later laps
var steerIntent:float = 0.0
var speed:float = 0.0

func _ready() -> void:
	millisAtStart = Time.get_ticks_msec()
	$WarpSound.play()
		
func _physics_process(delta: float) -> void:
	if nextWaypoint == null:
		# try to get our next destination
		var game:Game = get_parent()
		nextWaypoint = game.getWaypoint(nextWaypointIdx)
		if nextWaypoint == null:
			# if we don't know where we're going, just keep doing what we were doing
			print("Couldn't find next waypoint! Looking for: ", nextWaypointIdx)
			move_and_slide()
			return
		else:
			nextWaypointIdx += 1 #line up our next destination
	
	#are we there yet?
	var millisSinceStart = Time.get_ticks_msec() - millisAtStart + timeSkipMillis
	if millisSinceStart >= nextWaypoint.millisSinceStart:
		# we should be there.  Sync up!
		position = nextWaypoint.position
		rotation = nextWaypoint.rotation
		velocity = nextWaypoint.velocity # TODO might not need this
		speed = nextWaypoint.speed
		steerIntent = nextWaypoint.steerIntent
		nextWaypoint = null
		
		velocity = Vector2.RIGHT.rotated(rotation) * speed
		move_and_slide()
		return
	
	rotate(steerIntent*delta)
	
	
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	move_and_slide()
	
func despawn()->void:
	$WarpSound.play()
	$AnimationPlayer.play("despawn")
	
func onDespawnComplete()->void:
	queue_free()
