extends Control
class_name GameOverDialog

signal restartGameSignal

func updateLabel(lapsCompleted:int, lapsRequired:int):
	%StatsLabel.text = "Completed Laps: " + str(lapsCompleted) + " / " + str(lapsRequired)

func _on_play_again_button_pressed() -> void:
	restartGameSignal.emit()
