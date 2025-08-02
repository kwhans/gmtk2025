extends Node2D
class_name RaceTrack

func getTrackTiles() -> Array[Vector2i]:
	return $TileMapLayer2.get_used_cells()

var mostRecentMarker:int = 0
var nextMarker:int = 1
@export var finalMarker:int = 5

signal lapCompleteSignal
signal lapAlmostCompleteSignal

func _on_loop_marker_body_entered(_body: Node2D, markerNum: int) -> void:
	#print("Hit loop marker ", markerNum)
	var expectedRecentMarker = nextMarker-1
	if markerNum == nextMarker and (mostRecentMarker == expectedRecentMarker or expectedRecentMarker <= 0):
		# player isn't cheating, they legit reached this marker
		nextMarker += 1
		if nextMarker > finalMarker:
			nextMarker = 1
		if markerNum == finalMarker:
			lapCompleteSignal.emit()
			#celebrate()
		if markerNum == finalMarker - 1:
			lapAlmostCompleteSignal.emit()
	mostRecentMarker = markerNum

func celebrate()->void:
	$Confetti1.startEffect()
	$Confetti2.startEffect()
	
func getStartGlobalPosition() -> Vector2:
	return $StartPosition.global_position

func getStartGlobalRotation() -> float:
	return $StartPosition.global_rotation
	
