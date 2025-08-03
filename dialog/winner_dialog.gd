extends Control

signal newGameSignal

func _input(event: InputEvent) -> void:
	if visible == false:
		return
		
	if event.is_action_pressed("ui_accept"):
		newGameSignal.emit()
		

func _on_next_race_button_pressed() -> void:
	newGameSignal.emit()


func _on_credits_button_pressed() -> void:
	%CreditsDialog.visible = true
