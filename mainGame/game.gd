extends Node2D
class_name Game

var startCountDownIdx = 0
var startCountDownMessages = ["Ready?", "3", "2", "1", "GO!"]
var carHistory:Array[Waypoint] = []
var millisAtStart:int = 0;
var carStartPos:Vector2 = Vector2.ZERO
var carStartRotation:float = 0.0
var carStartSpeed:float = 0.0
var ghostCarScene = preload("res://car/ghostCar.tscn")
var oilSpillScene = preload("res://obstacles/OilSpill.tscn")
@export var spawnSafetyRadius:float = 600

func _ready() -> void:
	$Car.waypointSignal.connect(recordWaypoint)
	carStartPos = $Car.position
	carStartRotation = $Car.rotation
	carStartSpeed = $Car.speed
	%GameOverDialog.restartGameSignal.connect(restartGame)

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		%NarrationLabel.text = startCountDownMessages[startCountDownIdx]
		%NarrationLabel.visible = true
		startCountDownIdx += 1
		if startCountDownIdx == startCountDownMessages.size():
			$Car.go = true
			$GoSound.play()
			millisAtStart = Time.get_ticks_msec()
			recordWaypoint()
			$SpawnGhostTimer.start()
		elif startCountDownIdx > 1:
			$CountSound.play()
		elif startCountDownIdx == 1:
			$ReadySound.play()
	else:
		$StartCountDownTimer.stop()
		%NarrationLabel.visible = false

func recordWaypoint() -> void:
	if carHistory.size() > 1000000: #arbitrary limit so we can't overflow
		return
		
	var newWaypoint = Waypoint.new()
	newWaypoint.millisSinceStart = Time.get_ticks_msec() - millisAtStart
	newWaypoint.position = $Car.position
	newWaypoint.rotation = $Car.rotation
	newWaypoint.velocity = $Car.velocity
	newWaypoint.steerIntent = $Car.steerIntent
	newWaypoint.speed = $Car.netSpeed
	
	carHistory.append(newWaypoint)
	#print("Added waypoint ", carHistory.size())

func getWaypoint(waypointIdx:int) -> Waypoint:
	if waypointIdx >= carHistory.size() or waypointIdx < 0:
		return null
	return carHistory[waypointIdx]

func spawnGhostCar() -> void:
	var ghost = ghostCarScene.instantiate()
	ghost.position = carStartPos
	add_child(ghost)


func _on_spawn_ghost_timer_timeout() -> void:
	spawnGhostCar()


func _on_oil_timer_timeout() -> void:
	var tiles:Array[Vector2i] = $BasicTrack.getTrackTiles()
	var newOil:OilSpill = oilSpillScene.instantiate()
	var targetPosition:Vector2
	var goodTarget:bool = false
	while !goodTarget: #keep the oil from spawning right in front of the car
		var randomTile = tiles.pick_random()
		targetPosition = (randomTile * 128.0) + Vector2(randf_range(0,128),randf_range(0,128)) - $BasicTrack.position
		goodTarget = targetPosition.distance_to($Car.position) > spawnSafetyRadius
		#print_debug("recalculated position")
	newOil.position = targetPosition
	newOil.rotation = randf_range(0, TAU)
	$BasicTrack.add_child(newOil)

func doGameOver() -> void:
	$SpawnGhostTimer.stop()
	get_tree().paused = true
	$GameOverTimer.start()

func restartGame() -> void:
	$SpawnGhostTimer.stop() # just in case we did a reset without a game over
	
	%GameOverDialog.visible = false
	print("Restarting game...")
	
	# clear ghosts and waypoints
	var allGhosts = get_tree().get_nodes_in_group("Ghosts")
	for ghost in allGhosts:
		ghost.queue_free()
	
	carHistory.clear()
	
	# clear all obstacles
	var allObstacles = get_tree().get_nodes_in_group("Obstacles")
	for obs in allObstacles:
		obs.queue_free()
		
	# Fix the car
	$Car.go = false
	$Car.position = carStartPos
	$Car.rotation = carStartRotation
	$Car.revive()
	
	get_tree().paused = false
	
	startCountDownIdx = 0
	$StartCountDownTimer.start()
	

func _on_game_over_timer_timeout() -> void:
	%GameOverDialog.visible = true
