extends Control
class_name GameOverDialog

signal restartGameSignal


func _on_play_again_button_pressed() -> void:
	restartGameSignal.emit()
