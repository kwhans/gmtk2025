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
var barrelScene = preload("res://obstacles/barrelObstacle.tscn")
var barrelScene2 = preload("res://obstacles/sidewaysBarrel.tscn")
var wallScene1 = preload("res://obstacles/wallRed.tscn")
var wallScene2 = preload("res://obstacles/wallRedWithWord.tscn")
var wallScene3 = preload("res://obstacles/wallWhite.tscn")
var wallScene4 = preload("res://obstacles/wallWhiteWithWord.tscn")
var rockScene1 = preload("res://obstacles/Rock1.tscn")
var rockScene2 = preload("res://obstacles/Rock2.tscn")
var rockScene3 = preload("res://obstacles/Rock3.tscn")

var lapsCompleted:int = 0
var currentTrack:int = 0;

# Game parameters
@export var spawnSafetyRadius:float = 600
@export var totalLapsToWin:int = 8
@export var numberOfObstaclesToPlace:int = 10
@export var respawnAllGhosts:bool = false # if true all ghosts despawn each lap and one new ghost per lap is spawned
@export var spawnGhostsAhead:bool = true
@export var spawnGhostsBehind:bool = false
const NUMBER_OF_LEVELS = 4

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_up"):
		restartGame(true)
	#if event.is_action("ui_accept"):
	#	celebrate()

func _ready() -> void:
	carStartPos = $Car.position
	carStartRotation = $Car.rotation
	carStartSpeed = $Car.speed
	%LapCounter.updateLabel(lapsCompleted, totalLapsToWin)
	placeAllObstacles()

func getCurrentTrack() -> RaceTrack:
	if currentTrack % 2 == 0:
		return $BasicTrack
	else:
		return $BowTieTrack

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		%NarrationLabel.text = startCountDownMessages[startCountDownIdx]
		%NarrationLabel.visible = true
		%LevelNameLabel.visible = true
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
		%LevelNameLabel.visible = false

func recordWaypoint(isNewLap:bool) -> void:
	if lapsCompleted >= totalLapsToWin:
		return # stop recording after we win or it messes up the final time
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
	$WarpSound.play()
	spawnGhostCar()

func applyOdds(remainingOdds:int, nextOdds:int) -> int:
	return remainingOdds - nextOdds
	
func createRandomObstacle() -> Node2D:
	# Choose a random obstacle to place
	# Note that all obstacles should belong to group "Obstacles" so that they get cleared on a reset
	const oilOdds = 20
	const barrelOdds = 10 # per barrel type (2)
	const wallOdds = 1 # per wall type (4)
	const rockOdds = 1 # per rock type (3)
	const totalOdds = oilOdds + barrelOdds*2 + wallOdds*4 + rockOdds*3

	var pick = randi() % totalOdds
	pick -= oilOdds
	if pick < 0:
		return oilSpillScene.instantiate()
	pick -= barrelOdds
	if pick < 0:
		return barrelScene.instantiate()
	pick -= barrelOdds
	if pick < 0:
		return barrelScene2.instantiate()
	pick -= wallOdds
	if pick < 0:
		return wallScene1.instantiate()
	pick -= wallOdds
	if pick < 0:
		return wallScene2.instantiate()
	pick -= wallOdds
	if pick < 0:
		return wallScene3.instantiate()
	pick -= wallOdds
	if pick < 0:
		return wallScene4.instantiate()
	pick -= rockOdds
	if pick < 0:
		return rockScene1.instantiate()
	pick -= rockOdds
	if pick < 0:
		return rockScene2.instantiate()
	pick -= rockOdds
	if pick < 0:
		return rockScene3.instantiate()
	return oilSpillScene.instantiate()

func placeRandomObstacle() -> void:
	var tiles:Array[Vector2i] = getCurrentTrack().getTrackTiles()
	var targetPosition:Vector2
	var goodTarget:bool = false
	while !goodTarget: #keep the oil from spawning right in front of the car
		var randomTile = tiles.pick_random()
		targetPosition = (randomTile * 128.0) + Vector2(randf_range(0,128),randf_range(0,128)) - getCurrentTrack().position
		goodTarget = targetPosition.distance_to($Car.position) > spawnSafetyRadius
		#print_debug("recalculated position")
		
	var newNode:Node2D = createRandomObstacle()
	newNode.position = targetPosition
	newNode.rotation = randf_range(0, TAU)
	getCurrentTrack().add_child(newNode)
	
func _on_oil_timer_timeout() -> void:
	placeRandomObstacle()

func placeAllObstacles() -> void:
	for i in range(numberOfObstaclesToPlace):
		placeRandomObstacle()

func doGameOver() -> void:
	#$SpawnGhostTimer.stop()
	get_tree().paused = true
	$GameOverTimer.start()

func restartGame(changeTrack:bool) -> void:
	#$SpawnGhostTimer.stop() # just in case we did a reset without a game over
	
	%GameOverDialog.visible = false
	%RaceFinishedDialog.visible = false
	%WinnerDialog.visible = false
	print("Restarting game...")
	
	if changeTrack:
		switchTracks()
	else:
		%Instructions.reset()
	
	lapsCompleted = 0
	%LapCounter.updateLabel(lapsCompleted, totalLapsToWin)
	
	# clear ghosts and waypoints
	var allGhosts = get_tree().get_nodes_in_group("Ghosts")
	for ghost in allGhosts:
		ghost.queue_free()
	
	lapStartWaypoints.clear()
	carHistory.clear()
	
	# clear all obstacles
	var allObstacles = get_tree().get_nodes_in_group("Obstacles")
	for obs in allObstacles:
		obs.queue_free()
		
	# Fix the car
	$Car.go = false
	$Car.global_position = getCurrentTrack().getStartGlobalPosition()
	$Car.global_rotation = getCurrentTrack().getStartGlobalRotation()
	$Car.revive()
	
	# make new obstacles
	placeAllObstacles()
	
	# reset music
	$SoundTrack0.stop()
	$SoundTrack1.stop()
	$SoundTrack2.stop()
	$SoundTrack3.stop()
	$MusicStartTimer.start()
	
	get_tree().paused = false
	
	startCountDownIdx = 0
	$StartCountDownTimer.start()
	

func _on_game_over_timer_timeout() -> void:
	%GameOverDialog.visible = true


func _on_track_lap_complete_signal() -> void:
	recordWaypoint(true) # this has to come before incrementing lapsCompleted or else it stops recording before the last one
	lapsCompleted += 1
	%LapCounter.updateLabel(lapsCompleted, totalLapsToWin)
	%GameOverDialog.updateLabel(lapsCompleted,totalLapsToWin)
	$Car.lapsCompleted = lapsCompleted
	if lapsCompleted >= totalLapsToWin:
		finishRace()

func getLapsCompleted() -> int:
	return lapsCompleted
	
func getTotalLapsRequired() -> int:
	return totalLapsToWin

func _on_track_lap_almost_complete_signal() -> void:
	# remove previous lap ghosts
	var thisWillBeLastLap:bool = lapsCompleted == totalLapsToWin-2
	var thisWasLastLap:bool = lapsCompleted >= totalLapsToWin-1
	if respawnAllGhosts or thisWasLastLap or (thisWillBeLastLap and spawnGhostsAhead):
		var allGhosts = get_tree().get_nodes_in_group("Ghosts")
		if allGhosts.size() > 0:
			$WarpSound.play()
		for ghost in allGhosts:
			if ghost is GhostCar:
				ghost.despawn()
			else:
				ghost.queue_free()
	if thisWasLastLap or not spawnGhostsAhead:
		return

	if respawnAllGhosts or thisWillBeLastLap:
		# make a fresh batch of ghosts
		if lapStartWaypoints.size() > 0:
			$WarpSound.play()
		for wayPt in lapStartWaypoints:
			spawnGhostCar(wayPt)
	else:
		# just add one more
		$WarpSound.play()
		spawnGhostCar()
		
func _on_car_waypoint_signal() -> void:
	recordWaypoint(false)

func finishRace() -> void:
	#get_tree().paused = true
	celebrate() # start the firework countdown
	getCurrentTrack().celebrate() # fire off the confetti
	$GameWinPauseTimer.start()
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
	restartGame(false)

func _on_race_finished_dialog_next_race_signal() -> void:
	if currentTrack == NUMBER_OF_LEVELS - 1:
		%RaceFinishedDialog.visible = false
		%WinnerDialog.visible = true
	else:
		restartGame(true)

func _on_game_win_pause_timer_timeout() -> void:
	get_tree().paused = true

func celebrate()->void:
	playARandomCheerSound()
	$FireworkTimer1.start()
	$FireworkTimer2.start()
	$FireworkTimer3.start()


func _on_firework_timer_1_timeout() -> void:
	%Firework1.startEffect()


func _on_firework_timer_2_timeout() -> void:
	%Firework2.startEffect()


func _on_firework_timer_3_timeout() -> void:
	%Firework3.startEffect()


func _on_sound_track_finished() -> void:
	playARandomSoundTrack()

func playARandomSoundTrack()->void:
	var pick = randi() % 4
	match pick:
		0:
			$SoundTrack0.play()
		1:
			$SoundTrack1.play()
		2:
			$SoundTrack2.play()
		3:
			$SoundTrack3.play()


func _on_music_start_timer_timeout() -> void:
	playARandomSoundTrack()

func switchTracks():
	currentTrack = (currentTrack + 1) % NUMBER_OF_LEVELS
	match currentTrack:
		0:
			%LevelNameLabel.text = "Race 1: A Drive Through The Loop"
			$Car.lapAcceleration = 0.12
			totalLapsToWin = 8
			spawnGhostsAhead = true
			spawnGhostsBehind = false
			respawnAllGhosts = false
			$BasicTrack.process_mode = Node.PROCESS_MODE_INHERIT
			$BasicTrack.visible = true
			$BowTieTrack.visible = false
			$BowTieTrack.process_mode = Node.PROCESS_MODE_DISABLED
		1:
			%LevelNameLabel.text = "Race 2: Stay Out Of The Passing Lane"
			$Car.lapAcceleration = -0.1
			totalLapsToWin = 8
			spawnGhostsAhead = false
			spawnGhostsBehind = true
			respawnAllGhosts = false
			$BowTieTrack.process_mode = Node.PROCESS_MODE_INHERIT
			$BowTieTrack.visible = true
			$BasicTrack.visible = false
			$BasicTrack.process_mode = Node.PROCESS_MODE_DISABLED
		2:
			%LevelNameLabel.text = "Race 3: Sandwiched"
			$Car.lapAcceleration = 0.0
			totalLapsToWin = 8
			spawnGhostsAhead = true
			spawnGhostsBehind = true
			respawnAllGhosts = false
			$BasicTrack.process_mode = Node.PROCESS_MODE_INHERIT
			$BasicTrack.visible = true
			$BowTieTrack.visible = false
			$BowTieTrack.process_mode = Node.PROCESS_MODE_DISABLED
		3:
			%LevelNameLabel.text = "Race 4: The Wolf Pack"
			$Car.lapAcceleration = 0.0
			totalLapsToWin = 8
			spawnGhostsAhead = true
			spawnGhostsBehind = true
			respawnAllGhosts = true
			$BowTieTrack.process_mode = Node.PROCESS_MODE_INHERIT
			$BowTieTrack.visible = true
			$BasicTrack.visible = false
			$BasicTrack.process_mode = Node.PROCESS_MODE_DISABLED
		_:
			%LevelNameLabel.text = "Race 1: A Drive Through The Loop"
			$Car.lapAcceleration = 0.12
			totalLapsToWin = 8
			spawnGhostsAhead = true
			spawnGhostsBehind = false
			respawnAllGhosts = false
			$BasicTrack.process_mode = Node.PROCESS_MODE_INHERIT
			$BasicTrack.visible = true
			$BowTieTrack.visible = false
			$BowTieTrack.process_mode = Node.PROCESS_MODE_DISABLED
			
func _on_track_lap_just_started() -> void:
	var thisIsFirstLap:bool = lapsCompleted == 0
	if thisIsFirstLap or not spawnGhostsBehind:
		return
		
	var thisIsLastLap:bool = lapsCompleted == totalLapsToWin-1
	var raceIsFinished:bool = lapsCompleted >= totalLapsToWin
	
	if respawnAllGhosts or thisIsLastLap or raceIsFinished:
		if (spawnGhostsBehind != spawnGhostsAhead) or raceIsFinished:
			# remove previous lap ghosts
			var allGhosts = get_tree().get_nodes_in_group("Ghosts")
			if allGhosts.size() > 0:
				$WarpSound.play()
			for ghost in allGhosts:
				if ghost is GhostCar:
					ghost.despawn()
				else:
					ghost.queue_free()
				
		if raceIsFinished:
			return
			
		# make a fresh batch of ghosts
		var ghostCount = lapStartWaypoints.size()-1 # don't count most recent start (we just started it)
		if ghostCount > 0:
			$WarpSound.play()
		for i in range(ghostCount):
			var wayPt = lapStartWaypoints[i]
			spawnGhostCar(wayPt)
	else:
		# just add one more
		$WarpSound.play()
		spawnGhostCar()

func playARandomCheerSound()->void:
	var pick = randi() % 3
	match pick:
		0:
			$CheerSound0.play()
		1:
			$CheerSound1.play()
		2: 
			$CheerSound2.play()
		_:
			$CheerSound0.play()


func _on_winner_dialog_new_game_signal() -> void:
	restartGame(true)
