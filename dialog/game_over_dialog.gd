extends Control
class_name GameOverDialog

signal restartGameSignal

func _input(event: InputEvent) -> void:
	if visible == false:
		return
		
	if event.is_action_pressed("ui_accept"):
		restartGameSignal.emit()

func updateLabel(lapsCompleted:int, lapsRequired:int):
	%StatsLabel.text = "Completed Laps: " + str(lapsCompleted) + " / " + str(lapsRequired)

func _on_play_again_button_pressed() -> void:
	restartGameSignal.emit()
