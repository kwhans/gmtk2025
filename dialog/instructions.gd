extends MarginContainer


func _on_fade_out_timer_timeout() -> void:
	$AnimationPlayer.play("FadeOut")

func reset()->void:
	modulate = Color(1,1,1,1)
	visible = true
	$FadeOutTimer.start()
