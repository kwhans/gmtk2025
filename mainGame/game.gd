extends Node2D
class_name Game

var startCountDownIdx = 0
var startCountDownMessages = ["Ready?", "3", "2", "1", "GO!"]
var carHistory:Array[Waypoint] = []
var millisAtStart:int = 0;
var carStartPos:Vector2 = Vector2.ZERO
var ghostCarScene = preload("res://car/ghostCar.tscn")

func _ready() -> void:
	$Car.waypointSignal.connect(recordWaypoint)
	carStartPos = $Car.position

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		%NarrationLabel.text = startCountDownMessages[startCountDownIdx]
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
	newWaypoint.speed = $Car.speed
	
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
