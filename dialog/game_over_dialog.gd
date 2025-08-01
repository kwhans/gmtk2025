extends Control
class_name GameOverDialog

signal restartGameSignal
var game:Game = null

var mostRecentLapsCompleted = -1

func updateLabel(lapsCompleted:int, lapsRequired:int):
	%StatsLabel.text = "Completed Laps: " + str(lapsCompleted) + " / " + str(lapsRequired)

func _on_play_again_button_pressed() -> void:
	restartGameSignal.emit()
