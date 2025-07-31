extends Node2D

var startCountDownIdx = 0
var startCountDownMessages = ["Ready?", "3", "2", "1", "GO!"]

func _on_start_count_down_timer_timeout() -> void:
	if startCountDownIdx < startCountDownMessages.size():
		$CenterContainer/NarrationLabel.text = startCountDownMessages[startCountDownIdx]
		startCountDownIdx += 1
		if startCountDownIdx == startCountDownMessages.size():
			$Car.go = true
			$GoSound.play()
		elif startCountDownIdx > 1:
			$CountSound.play()
	else:
		$StartCountDownTimer.stop()
		$CenterContainer/NarrationLabel.visible = false
