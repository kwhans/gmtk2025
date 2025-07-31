extends Node2D

var startCountDownIdx = 0
var startCountDownMessages = ["Ready?", "3", "2", "1", "GO!"]
var oilSpillScene = preload("res://obstacles/OilSpill.tscn")
@export var spawnSafetyRadius:float = 600

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		%NarrationLabel.text = startCountDownMessages[startCountDownIdx]
		startCountDownIdx += 1
		if startCountDownIdx == startCountDownMessages.size():
			$Car.go = true
			$GoSound.play()
		elif startCountDownIdx > 1:
			$CountSound.play()
	else:
		$StartCountDownTimer.stop()
		%NarrationLabel.visible = false


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
