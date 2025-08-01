extends Node2D
class_name Game

var startCountDownIdx = 0
var startCountDownMessages = ["Ready?", "3", "2", "1", "GO!"]
var carHistory:Array[Waypoint] = []
var lapStartWaypoints:Array[int] = []
var millisAtStart:int = 0;
var carStartPos:Vector2 = Vector2.ZERO
var carStartRotation:float = 0.0
var carStartSpeed:float = 0.0
var ghostCarScene = preload("res://car/ghostCar.tscn")
var oilSpillScene = preload("res://obstacles/OilSpill.tscn")
@export var spawnSafetyRadius:float = 600
var lapsCompleted:int = 0
var totalLapsToWin:int = 10

func _ready() -> void:
	carStartPos = $Car.position
	carStartRotation = $Car.rotation
	carStartSpeed = $Car.speed

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		%NarrationLabel.text = startCountDownMessages[startCountDownIdx]
		%NarrationLabel.visible = true
		startCountDownIdx += 1
		if startCountDownIdx == startCountDownMessages.size():
			$Car.go = true
			$GoSound.play()
			millisAtStart = Time.get_ticks_msec()
			recordWaypoint(true)
			#$SpawnGhostTimer.start()
		elif startCountDownIdx > 1:
			$CountSound.play()
		elif startCountDownIdx == 1:
			$ReadySound.play()
	else:
		$StartCountDownTimer.stop()
		%NarrationLabel.visible = false

func recordWaypoint(isNewLap:bool) -> void:
	if carHistory.size() > 10000000: #arbitrary limit so we can't overflow
		return
		
	var newWaypoint = Waypoint.new()
	newWaypoint.millisSinceStart = Time.get_ticks_msec() - millisAtStart
	newWaypoint.position = $Car.position
	newWaypoint.rotation = $Car.rotation
	newWaypoint.velocity = $Car.velocity
	newWaypoint.steerIntent = $Car.steerIntent
	newWaypoint.speed = $Car.netSpeed
	
	carHistory.append(newWaypoint)
	
	if(isNewLap):
		lapStartWaypoints.append(carHistory.size()-1)
	#print("Added waypoint ", carHistory.size())

func getWaypoint(waypointIdx:int) -> Waypoint:
	if waypointIdx >= carHistory.size() or waypointIdx < 0:
		return null
	return carHistory[waypointIdx]

func spawnGhostCar(startingWaypointIdx:int=0) -> void:
	var ghost:GhostCar = ghostCarScene.instantiate()
	
	#start at specified waypoint if available
	if startingWaypointIdx > 0 and startingWaypointIdx < carHistory.size():
		# This ghost is skipping to a later lap
		var wayPt:Waypoint = carHistory[startingWaypointIdx]
		ghost.nextWaypointIdx = startingWaypointIdx
		ghost.timeSkipMillis = wayPt.millisSinceStart
		ghost.position = wayPt.position
		ghost.rotation = wayPt.rotation
		ghost.speed = wayPt.speed
		ghost.steerIntent = wayPt.steerIntent
	else:
		ghost.position = carStartPos
	call_deferred("add_child", ghost)


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
	#$SpawnGhostTimer.stop()
	get_tree().paused = true
	$GameOverTimer.start()

func restartGame() -> void:
	#$SpawnGhostTimer.stop() # just in case we did a reset without a game over
	
	%GameOverDialog.visible = false
	%RaceFinishedDialog.visible = false
	print("Restarting game...")
	
	lapsCompleted = 0
	
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


func _on_basic_track_lap_complete_signal() -> void:
	lapsCompleted += 1
	recordWaypoint(true)
	%GameOverDialog.updateLabel(lapsCompleted,totalLapsToWin)
	$Car.lapsCompleted = lapsCompleted
	if lapsCompleted >= totalLapsToWin:
		finishRace()

func getLapsCompleted() -> int:
	return lapsCompleted
	
func getTotalLapsRequired() -> int:
	return totalLapsToWin

func _on_basic_track_lap_almost_complete_signal() -> void:
	# remove previous lap ghosts
	var allGhosts = get_tree().get_nodes_in_group("Ghosts")
	for ghost in allGhosts:
		ghost.queue_free()
		
	# make a fresh batch of ghosts
	for wayPt in lapStartWaypoints:
		spawnGhostCar(wayPt)
	

func _on_car_waypoint_signal() -> void:
	recordWaypoint(false)

func finishRace() -> void:
	get_tree().paused = true
	#TODO celebration
	$GameWinTimer.start()

func _on_game_win_timer_timeout() -> void:
	if carHistory.size() < 1:
		return
		
	var lastWaypoint = carHistory[carHistory.size()-1]
	var totalTimeSec = lastWaypoint.millisSinceStart / 1000.0
	
	var bestTimeMs = 999999999
	var bestLap = 0
	var worstTimeMs = 0
	var worstLap = 0
	var previousLapEnd = 0
	var lapCounter = 0
	for wayPtIdx in lapStartWaypoints:
		# skip first waypoint or your best time will be 0
		if wayPtIdx == 0:
			continue 
		lapCounter += 1
		var wp:Waypoint = carHistory[wayPtIdx]
		var lapTime = wp.millisSinceStart - previousLapEnd
		if lapTime < bestTimeMs:
			bestTimeMs = lapTime
			bestLap = lapCounter
		if lapTime > worstTimeMs:
			worstTimeMs = lapTime
			worstLap = lapCounter
		previousLapEnd = wp.millisSinceStart
	var bestLapSec = bestTimeMs / 1000.0
	var worstLapSec = worstTimeMs / 1000.0
	
	%RaceFinishedDialog.updateLabels(totalTimeSec, bestLap, bestLapSec, worstLap, worstLapSec)
	%RaceFinishedDialog.visible = true

func _on_game_over_dialog_restart_game_signal() -> void:
	restartGame()

func _on_race_finished_dialog_next_race_signal() -> void:
	# TODO load next level
	restartGame()
